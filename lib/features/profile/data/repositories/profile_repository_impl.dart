import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/user_address_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_datasource.dart';
import '../models/user_address_model.dart';
import '../models/wallet_transaction_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource dataSource;

  ProfileRepositoryImpl({required this.dataSource});

  @override
  Future<List<UserAddressEntity>> getSavedAddresses() {
    return dataSource.getSavedAddresses();
  }

  @override
  Future<void> addAddress(UserAddressEntity address) {
    return dataSource.addAddress(UserAddressModel.fromEntity(address));
  }

  @override
  Future<void> updateAddress(UserAddressEntity address) {
    return dataSource.updateAddress(UserAddressModel.fromEntity(address));
  }

  @override
  Future<void> deleteAddress(String addressId) {
    return dataSource.deleteAddress(addressId);
  }

  @override
  Future<double> getWalletBalance() {
    return dataSource.getWalletBalance();
  }

  @override
  Future<List<WalletTransactionModel>> getWalletTransactions({
    int page = 1,
    int limit = 40,
  }) {
    return dataSource.getWalletTransactions(page: page, limit: limit);
  }

  @override
  Future<UserEntity> updateProfile({
    required String name,
    required String email,
    String? avatar,
  }) {
    return dataSource.updateProfile(name, email, avatar: avatar);
  }
}
