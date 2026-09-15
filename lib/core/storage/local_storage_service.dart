import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // Token management
  Future<bool> setCustomerToken(String token) =>
      _prefs.setString(StorageKeys.authCustomer, token);

  String? getCustomerToken() => _prefs.getString(StorageKeys.authCustomer);

  Future<bool> clearCustomerToken() => _prefs.remove(StorageKeys.authCustomer);

  // Active Role
  Future<bool> setActiveRole(String role) =>
      _prefs.setString(StorageKeys.activeRole, role);

  String getActiveRole() => _prefs.getString(StorageKeys.activeRole) ?? 'customer';

  // Generic helpers
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);
  Future<bool> remove(String key) => _prefs.remove(key);

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
