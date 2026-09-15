import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/services/firebase_notification_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final SocketService? socketService;

  AuthBloc({required this.authRepository, this.socketService})
      : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthUserUpdated>(_onUserUpdated);
    on<AuthModeSwitched>(_onModeSwitched);
    on<AuthSendOtpRequested>(_onSendOtpRequested);
    on<AuthVerifyOtpRequested>(_onVerifyOtpRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  void _onUserUpdated(
    AuthUserUpdated event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      user: event.user,
      name: event.user.name,
      phone: event.user.phone,
    ));
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final isAuth = await authRepository.isAuthenticated();
      if (isAuth) {
        final user = await authRepository.getProfile();
        emit(
          state.copyWith(isLoading: false, isAuthenticated: true, user: user),
        );
      } else {
        emit(
          state.copyWith(isLoading: false, isAuthenticated: false, user: null),
        );
      }
    } catch (_) {
      emit(state.copyWith(isLoading: false, isAuthenticated: false));
    }
  }

  void _onModeSwitched(AuthModeSwitched event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        mode: event.mode,
        step: AuthStep.identity,
        errorMessage: null,
        wrongMode: null,
        otpSent: false,
        isSuccessAccepted: false,
      ),
    );
  }

  Future<void> _onSendOtpRequested(
    AuthSendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, wrongMode: null));
    try {
      if (event.isLogin) {
        await authRepository.sendLoginOtp(phone: event.phone);
      } else {
        await authRepository.sendSignupOtp(
          name: event.name,
          phone: event.phone,
        );
      }
      emit(
        state.copyWith(
          isLoading: false,
          step: AuthStep.code,
          phone: event.phone,
          name: event.name,
          otpSent: true,
          errorMessage: null,
        ),
      );
    } on ApiException catch (e) {
      if (e.code == 'NOT_REGISTERED') {
        emit(
          state.copyWith(
            isLoading: false,
            wrongMode: 'signup',
            phone: event.phone,
          ),
        );
      } else if (e.code == 'ALREADY_REGISTERED') {
        emit(
          state.copyWith(
            isLoading: false,
            wrongMode: 'login',
            phone: event.phone,
          ),
        );
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: e.message));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: "Couldn't send the code. Please try again.",
        ),
      );
    }
  }

  Future<void> _onVerifyOtpRequested(
    AuthVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final phoneToUse = event.phone.trim().isNotEmpty
        ? event.phone.trim()
        : state.phone;
    final nameToUse = event.name.trim().isNotEmpty
        ? event.name.trim()
        : state.name;

    try {
      final user = event.isLogin
          ? await authRepository.verifyLoginOtp(
              phone: phoneToUse,
              otp: event.otp,
            )
          : await authRepository.verifySignupOtp(
              name: nameToUse,
              phone: phoneToUse,
              otp: event.otp,
            );

      emit(state.copyWith(isLoading: false, isSuccessAccepted: true));

      // A fresh session invalidates any previous 401 lockout.
      ApiClient.resetUnauthorizedGuard();

      // The token is in secure storage by now, so /push/register will
      // authenticate. Not awaited — a slow or failing registration must not
      // delay the transition into the app.
      unawaited(FirebaseNotificationService().registerTokenWithBackend());

      await Future.delayed(const Duration(milliseconds: 700));

      emit(state.copyWith(isAuthenticated: true, user: user));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid verification code.',
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Detach the device before the token is cleared — /push/remove is
    // authenticated, so the order matters. Otherwise a signed-out phone keeps
    // receiving the previous customer's parcel notifications.
    try {
      await FirebaseNotificationService().removeTokenFromBackend();
    } catch (_) {}

    await authRepository.logout();

    // The socket is authenticated with the old JWT and is still joined to the
    // previous customer's room; drop it so the next sign-in reconnects clean.
    socketService?.reset();
    ApiClient.resetUnauthorizedGuard();

    emit(const AuthState(isAuthenticated: false));
  }
}
