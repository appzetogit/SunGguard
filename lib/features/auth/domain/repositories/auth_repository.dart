import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<void> sendLoginOtp({required String phone});
  Future<void> sendSignupOtp({required String name, required String phone});
  Future<UserEntity> verifyLoginOtp({
    required String phone,
    required String otp,
  });
  Future<UserEntity> verifySignupOtp({
    required String name,
    required String phone,
    required String otp,
  });
  Future<UserEntity?> getProfile();
  Future<void> logout();
  Future<bool> isAuthenticated();
}
