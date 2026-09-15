import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

enum AuthStep { identity, code }

class AuthState extends Equatable {
  final bool isLoading;
  final bool isAuthenticated;
  final UserEntity? user;
  final String mode; // 'login' | 'signup'
  final AuthStep step;
  final String phone;
  final String name;
  final String? errorMessage;
  final String? wrongMode; // 'login' | 'signup' | null
  final bool otpSent;
  final bool isSuccessAccepted;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.mode = 'login',
    this.step = AuthStep.identity,
    this.phone = '',
    this.name = '',
    this.errorMessage,
    this.wrongMode,
    this.otpSent = false,
    this.isSuccessAccepted = false,
  });

  bool get isLogin => mode == 'login';

  /// Distinguishes "leave `user` alone" from "clear `user`".
  ///
  /// With a plain `user ?? this.user` the sign-out path could never null the
  /// user out, so a stale profile survived a failed auth check and the app
  /// rendered the previous customer's name on the sign-in screen.
  static const Object _unset = Object();

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Object? user = _unset,
    String? mode,
    AuthStep? step,
    String? phone,
    String? name,
    String? errorMessage,
    String? wrongMode,
    bool? otpSent,
    bool? isSuccessAccepted,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: identical(user, _unset) ? this.user : user as UserEntity?,
      mode: mode ?? this.mode,
      step: step ?? this.step,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      errorMessage: errorMessage,
      wrongMode: wrongMode,
      otpSent: otpSent ?? this.otpSent,
      isSuccessAccepted: isSuccessAccepted ?? this.isSuccessAccepted,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isAuthenticated,
        user,
        mode,
        step,
        phone,
        name,
        errorMessage,
        wrongMode,
        otpSent,
        isSuccessAccepted,
      ];
}
