import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_address_model.dart';
import '../models/wallet_transaction_model.dart';
import '../../../auth/data/models/user_model.dart';

abstract class ProfileDataSource {
  Future<List<UserAddressModel>> getSavedAddresses();
  Future<void> addAddress(UserAddressModel address);
  Future<void> updateAddress(UserAddressModel address);
  Future<void> deleteAddress(String addressId);
  Future<double> getWalletBalance();
  Future<List<WalletTransactionModel>> getWalletTransactions({
    int page,
    int limit,
  });
  Future<UserModel> updateProfile(String name, String email, {String? avatar});
}

class ProfileDataSourceImpl implements ProfileDataSource {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  static const String _storageKeyAddresses = 'saved_customer_addresses';

  ProfileDataSourceImpl({
    required this.apiClient,
    SecureStorageService? storageService,
  }) : storageService = storageService ?? SecureStorageService();

  @override
  Future<List<UserAddressModel>> getSavedAddresses() async {
    try {
      storageService.delete(_storageKeyAddresses);
      final res = await apiClient.get(ApiEndpoints.customerProfile);
      final result =
          (res is Map) ? (res['result'] ?? res['data'] ?? res['customer'] ?? res) : null;
      if (result is Map) {
        final rawAddresses = result['addresses'] ??
            (result['customer'] is Map ? result['customer']['addresses'] : null) ??
            (result['user'] is Map ? result['user']['addresses'] : null);
        if (rawAddresses is List) {
          return rawAddresses
              .whereType<Map<String, dynamic>>()
              .map((e) => UserAddressModel.fromJson(e))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> addAddress(UserAddressModel address) async {
    final current = await getSavedAddresses();
    final updated = [...current.where((a) => a.id != address.id), address];
    await apiClient.put(
      ApiEndpoints.customerUpdateProfile,
      data: {'addresses': updated.map((e) => e.toApiJson()).toList()},
    );
  }

  @override
  Future<void> updateAddress(UserAddressModel address) async {
    final current = await getSavedAddresses();
    final index = current.indexWhere((a) => a.id == address.id);
    final updated = List<UserAddressModel>.from(current);
    if (index >= 0) {
      updated[index] = address;
    } else {
      updated.add(address);
    }
    await apiClient.put(
      ApiEndpoints.customerUpdateProfile,
      data: {'addresses': updated.map((e) => e.toApiJson()).toList()},
    );
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    final current = await getSavedAddresses();
    final updated = current.where((a) => a.id != addressId).toList();
    await apiClient.put(
      ApiEndpoints.customerUpdateProfile,
      data: {'addresses': updated.map((e) => e.toApiJson()).toList()},
    );
  }

  @override
  Future<double> getWalletBalance() async {
    try {
      final res = await apiClient.get(ApiEndpoints.customerProfile);
      final result = (res is Map) ? (res['result'] ?? res['data'] ?? res) : null;
      if (result is Map && result['walletBalance'] != null) {
        return (result['walletBalance'] as num).toDouble();
      }
    } catch (_) {}

    try {
      final res = await apiClient.get(ApiEndpoints.wallet);
      if (res is Map && res['balance'] != null) {
        return (res['balance'] as num).toDouble();
      }
    } catch (_) {}

    return 0.0;
  }

  @override
  Future<List<WalletTransactionModel>> getWalletTransactions({
    int page = 1,
    int limit = 40,
  }) async {
    // This used to return a hardcoded empty list, so the wallet page bypassed
    // the repository entirely and fetched the same endpoint itself.
    try {
      final res = await apiClient.get(
        ApiEndpoints.customerTransactions,
        // Server clamps limit to 50.
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = (res is Map) ? (res['result'] ?? res['data'] ?? res) : null;
      if (data is Map && data['items'] is List) {
        return (data['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(WalletTransactionModel.fromJson)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  @override
  Future<UserModel> updateProfile(
    String name,
    String email, {
    String? avatar,
  }) async {
    final res = await apiClient.put(
      ApiEndpoints.customerUpdateProfile,
      data: {
        'name': name,
        'email': email,
        // Only sent when the customer actually changed it — the server treats
        // an explicit empty string as "clear my avatar".
        if (avatar != null) 'avatar': avatar,
      },
    );
    final data = (res is Map<String, dynamic>)
        ? (res['result'] ?? res['data'] ?? res['customer'] ?? res['user'] ?? res) as Map<String, dynamic>
        : <String, dynamic>{};
    return UserModel.fromJson(data);
  }
}
