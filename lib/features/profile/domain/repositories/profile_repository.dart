import '../../domain/entities/user_address_entity.dart';
import '../../data/models/wallet_transaction_model.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract class ProfileRepository {
  Future<List<UserAddressEntity>> getSavedAddresses();
  Future<void> addAddress(UserAddressEntity address);
  Future<void> updateAddress(UserAddressEntity address);
  Future<void> deleteAddress(String addressId);
  Future<double> getWalletBalance();
  Future<List<WalletTransactionModel>> getWalletTransactions({
    int page,
    int limit,
  });
  Future<UserEntity> updateProfile({
    required String name,
    required String email,
    String? avatar,
  });
}
