import 'package:equatable/equatable.dart';
import '../../data/models/wallet_transaction_model.dart';
import '../../domain/entities/user_address_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';

class ProfileState extends Equatable {
  final bool isLoading;
  final List<UserAddressEntity> addresses;
  final double walletBalance;
  final List<WalletTransactionModel> transactions;
  final String? errorMessage;
  final bool isUpdated;
  final UserEntity? updatedUser;

  const ProfileState({
    this.isLoading = false,
    this.addresses = const [],
    this.walletBalance = 0.0,
    this.transactions = const [],
    this.errorMessage,
    this.isUpdated = false,
    this.updatedUser,
  });

  ProfileState copyWith({
    bool? isLoading,
    List<UserAddressEntity>? addresses,
    double? walletBalance,
    List<WalletTransactionModel>? transactions,
    String? errorMessage,
    bool? isUpdated,
    UserEntity? updatedUser,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      addresses: addresses ?? this.addresses,
      walletBalance: walletBalance ?? this.walletBalance,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage,
      isUpdated: isUpdated ?? false,
      updatedUser: updatedUser ?? this.updatedUser,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        addresses,
        walletBalance,
        transactions,
        errorMessage,
        isUpdated,
        updatedUser,
      ];
}
