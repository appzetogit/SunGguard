import 'package:equatable/equatable.dart';

class UserAddressEntity extends Equatable {
  final String id;
  final String label; // 'Home' | 'Work' | 'Other'
  final String fullAddress;
  final String line;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final String name;
  final String phone;
  final bool isDefault;

  /// Coordinates, persisted by the backend as `location: {lat, lng}`.
  ///
  /// The app never sent these, so a saved address had no position — and both
  /// booking flows require one. That is why the address book could not be
  /// used to book anything.
  final double? lat;
  final double? lng;

  /// Google's canonical strings for the same place, also part of the schema.
  final String formattedAddress;
  final String placeId;

  const UserAddressEntity({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.line,
    required this.landmark,
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.name = '',
    this.phone = '',
    this.isDefault = false,
    this.lat,
    this.lng,
    this.formattedAddress = '',
    this.placeId = '',
  });

  /// True when this address carries enough detail to start a booking from.
  bool get isBookable =>
      fullAddress.trim().length >= 5 && lat != null && lng != null;

  @override
  List<Object?> get props => [
        id,
        label,
        fullAddress,
        line,
        landmark,
        city,
        state,
        pincode,
        name,
        phone,
        isDefault,
        lat,
        lng,
        formattedAddress,
        placeId,
      ];
}
