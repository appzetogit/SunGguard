import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;
  final LocalStorageService localStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
    required this.localStorage,
  });

  @override
  Future<void> sendLoginOtp({required String phone}) {
    return remoteDataSource.sendLoginOtp(phone);
  }

  @override
  Future<void> sendSignupOtp({required String name, required String phone}) {
    return remoteDataSource.sendSignupOtp(name, phone);
  }

  @override
  Future<UserEntity> verifyLoginOtp({required String phone, required String otp}) async {
    final user = await remoteDataSource.verifyLoginOtp(phone, otp);
    if (user.token != null && user.token!.isNotEmpty) {
      await secureStorage.saveCustomerToken(user.token!);
      await secureStorage.setLoggedIn(true);
      await localStorage.setActiveRole('customer');
    }
    return user;
  }

  @override
  Future<UserEntity> verifySignupOtp({
    required String name,
    required String phone,
    required String otp,
  }) async {
    final user = await remoteDataSource.verifySignupOtp(name, phone, otp);
    if (user.token != null && user.token!.isNotEmpty) {
      await secureStorage.saveCustomerToken(user.token!);
      await secureStorage.setLoggedIn(true);
      await localStorage.setActiveRole('customer');
    }
    return user;
  }

  @override
  Future<UserEntity?> getProfile() async {
    final token = await secureStorage.getCustomerToken();
    if (token == null || token.isEmpty) return null;
    return remoteDataSource.getProfile();
  }

  @override
  Future<void> logout() async {
    await secureStorage.removeCustomerToken();
    await secureStorage.setLoggedIn(false);
    // Clear the plaintext mirror and the cached role too. Leaving these behind
    // meant a second customer signing in on the same device inherited the
    // previous session's cached identity.
    await localStorage.clearCustomerToken();
    await localStorage.remove(StorageKeys.userData);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await secureStorage.getCustomerToken();
    return token != null && token.isNotEmpty;
  }
}
