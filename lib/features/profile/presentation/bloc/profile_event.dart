import 'package:equatable/equatable.dart';
import '../../domain/entities/user_address_entity.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileFetchRequested extends ProfileEvent {}

class ProfileAddAddressRequested extends ProfileEvent {
  final UserAddressEntity address;

  const ProfileAddAddressRequested(this.address);

  @override
  List<Object?> get props => [address];
}

class ProfileEditAddressRequested extends ProfileEvent {
  final UserAddressEntity address;

  const ProfileEditAddressRequested(this.address);

  @override
  List<Object?> get props => [address];
}

class ProfileDeleteAddressRequested extends ProfileEvent {
  final String addressId;

  const ProfileDeleteAddressRequested(this.addressId);

  @override
  List<Object?> get props => [addressId];
}

class ProfileUpdateRequested extends ProfileEvent {
  final String name;
  final String email;

  /// Hosted URL of a newly uploaded avatar, or null to leave it unchanged.
  final String? avatar;

  const ProfileUpdateRequested({
    required this.name,
    required this.email,
    this.avatar,
  });

  @override
  List<Object?> get props => [name, email, avatar];
}
