import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final String? token;

  /// Hosted avatar URL. The server has always accepted and returned this on
  /// /customer/profile; the app had nowhere to put it.
  final String avatar;

  const UserEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.token,
    this.avatar = '',
  });

  @override
  List<Object?> get props => [id, name, phone, email, role, token, avatar];
}
