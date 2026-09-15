import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  // Generic write
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Generic read
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  // Generic delete
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  // Clear all secure credentials
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Role-specific token helpers
  Future<void> saveCustomerToken(String token) => write(StorageKeys.customerToken, token);
  Future<String?> getCustomerToken() => read(StorageKeys.customerToken);
  Future<void> removeCustomerToken() => delete(StorageKeys.customerToken);

  Future<void> saveDeliveryToken(String token) => write(StorageKeys.deliveryToken, token);
  Future<String?> getDeliveryToken() => read(StorageKeys.deliveryToken);
  Future<void> removeDeliveryToken() => delete(StorageKeys.deliveryToken);

  Future<void> saveSellerToken(String token) => write(StorageKeys.sellerToken, token);
  Future<String?> getSellerToken() => read(StorageKeys.sellerToken);
  Future<void> removeSellerToken() => delete(StorageKeys.sellerToken);

  Future<void> saveAdminToken(String token) => write(StorageKeys.adminToken, token);
  Future<String?> getAdminToken() => read(StorageKeys.adminToken);
  Future<void> removeAdminToken() => delete(StorageKeys.adminToken);

  // Boolean auth logged-in flag helpers
  Future<void> setLoggedIn(bool value) async {
    try {
      await write(StorageKeys.isLoggedIn, value ? 'true' : 'false');
    } catch (_) {}
  }

  Future<bool> getIsLoggedIn() async {
    try {
      final val = await read(StorageKeys.isLoggedIn);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }
}
