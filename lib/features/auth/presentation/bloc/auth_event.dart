import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthUserUpdated extends AuthEvent {
  final UserEntity user;

  const AuthUserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthModeSwitched extends AuthEvent {
  final String mode; // 'login' | 'signup'

  const AuthModeSwitched(this.mode);

  @override
  List<Object?> get props => [mode];
}

class AuthSendOtpRequested extends AuthEvent {
  final String name;
  final String phone;
  final bool isLogin;

  const AuthSendOtpRequested({
    required this.name,
    required this.phone,
    required this.isLogin,
  });

  @override
  List<Object?> get props => [name, phone, isLogin];
}

class AuthVerifyOtpRequested extends AuthEvent {
  final String name;
  final String phone;
  final String otp;
  final bool isLogin;

  const AuthVerifyOtpRequested({
    required this.name,
    required this.phone,
    required this.otp,
    required this.isLogin,
  });

  @override
  List<Object?> get props => [name, phone, otp, isLogin];
}

class AuthLogoutRequested extends AuthEvent {}
