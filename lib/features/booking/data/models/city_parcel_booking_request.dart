import 'package:equatable/equatable.dart';

/// One end of a city trip.
///
/// `line` and `landmark` are local-only: the backend's address schema accepts
/// exactly `fullAddress`, `lat`, `lng` and `addressNote`, and strips anything
/// else, so both are folded into `addressNote` on the way out.
class AddressData extends Equatable {
  final String fullAddress;
  final String line;
  final String landmark;
  final double? lat;
  final double? lng;

  /// Optional 6-digit PIN (`^[1-9]\d{5}$` on the server).
  final String pincode;

  const AddressData({
    required this.fullAddress,
    this.line = '',
    this.landmark = '',
    this.lat,
    this.lng,
    this.pincode = '',
  });

  static final RegExp pincodePattern = RegExp(r'^[1-9]\d{5}$');

  bool get hasValidPincode =>
      pincode.trim().isEmpty || pincodePattern.hasMatch(pincode.trim());

  /// True once the address can actually be submitted.
  ///
  /// `lat`/`lng` are `required` in the server schema. They used to be emitted
  /// conditionally, so an address typed without dropping a map pin produced a
  /// 400 the customer had no way to interpret.
  bool get isComplete =>
      fullAddress.trim().length >= 5 && lat != null && lng != null;

  String get _note {
    final parts = [landmark.trim(), line.trim()].where((p) => p.isNotEmpty);
    final joined = parts.join(', ');
    return joined.length > 200 ? joined.substring(0, 200) : joined;
  }

  Map<String, dynamic> toJson({bool isPickup = true}) => {
        'fullAddress': fullAddress.trim(),
        'lat': lat,
        'lng': lng,
        if (_note.isNotEmpty) 'addressNote': _note,
        if (pincode.trim().isNotEmpty && hasValidPincode) 'pincode': pincode.trim(),
      };

  AddressData copyWith({
    String? fullAddress,
    String? line,
    String? landmark,
    double? lat,
    double? lng,
    String? pincode,
  }) =>
      AddressData(
        fullAddress: fullAddress ?? this.fullAddress,
        line: line ?? this.line,
        landmark: landmark ?? this.landmark,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        pincode: pincode ?? this.pincode,
      );

  @override
  List<Object?> get props => [fullAddress, line, landmark, lat, lng, pincode];
}

class PersonData extends Equatable {
  final String name;
  final String phone;

  /// Backup number for the receiver. Optional on the server.
  final String altPhone;

  /// Lets somebody other than the named receiver accept the parcel. The
  /// booking form has always asked this; it now actually reaches the server.
  final bool allowAlternate;

  const PersonData({
    required this.name,
    required this.phone,
    this.altPhone = '',
    this.allowAlternate = false,
  });

  String get _cleanPhone => phone.replaceAll(RegExp(r'[\s-]'), '');

  /// Sender payload — the server's sender schema takes name and phone only.
  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': _cleanPhone,
      };

  /// Receiver payload, which additionally carries the alternate-collection
  /// fields the server's receiver schema accepts.
  Map<String, dynamic> toReceiverJson() {
    final alt = altPhone.replaceAll(RegExp(r'[\s-]'), '');
    return {
      'name': name,
      'phone': _cleanPhone,
      if (alt.isNotEmpty) 'altPhone': alt,
      'allowAlternate': allowAlternate,
    };
  }

  PersonData copyWith({
    String? name,
    String? phone,
    String? altPhone,
    bool? allowAlternate,
  }) =>
      PersonData(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        altPhone: altPhone ?? this.altPhone,
        allowAlternate: allowAlternate ?? this.allowAlternate,
      );

  @override
  List<Object?> get props => [name, phone, altPhone, allowAlternate];
}

class PackageData extends Equatable {
  final String packageType;
  final double weightKg;
  final String description;

  /// Declared contents value, used for disputes. Server accepts 0–1,000,000.
  final double declaredValue;

  const PackageData({
    required this.packageType,
    required this.weightKg,
    this.description = '',
    this.declaredValue = 0,
  });

  Map<String, dynamic> toJson() => {
        'packageType': packageType.isNotEmpty ? packageType : 'Documents',
        'weightKg': weightKg,
        'description': description,
        if (declaredValue > 0) 'declaredValue': declaredValue,
      };

  PackageData copyWith({
    String? packageType,
    double? weightKg,
    String? description,
    double? declaredValue,
  }) =>
      PackageData(
        packageType: packageType ?? this.packageType,
        weightKg: weightKg ?? this.weightKg,
        description: description ?? this.description,
        declaredValue: declaredValue ?? this.declaredValue,
      );

  @override
  List<Object?> get props =>
      [packageType, weightKg, description, declaredValue];
}

class CityParcelBookingRequest {
  final AddressData pickupAddress;
  final AddressData dropAddress;
  final PersonData sender;
  final PersonData receiver;
  final PackageData package;
  final String paymentMethod;
  final String deliverySpeed;
  final String? couponCode;

  const CityParcelBookingRequest({
    required this.pickupAddress,
    required this.dropAddress,
    required this.sender,
    required this.receiver,
    required this.package,
    this.paymentMethod = 'UPI',
    this.deliverySpeed = 'normal',
    this.couponCode,
  });

  /// Body shared by calculate-fare, coupon/validate and create.
  static Map<String, dynamic> quoteBody({
    required AddressData pickup,
    required AddressData drop,
    required PackageData package,
    required String deliverySpeed,
  }) =>
      {
        'pickupAddress': pickup.toJson(isPickup: true),
        'dropAddress': drop.toJson(isPickup: false),
        'package': package.toJson(),
        'deliverySpeed': deliverySpeed,
      };

  /// The server accepts UPI, CARD, WALLET and COD only.
  String get _normalizedPaymentMethod {
    final upper = paymentMethod.trim().toUpperCase();
    if (upper == 'CASH') return 'COD';
    return upper;
  }

  Map<String, dynamic> toJson() => {
        'pickupAddress': pickupAddress.toJson(isPickup: true),
        'dropAddress': dropAddress.toJson(isPickup: false),
        'sender': sender.toJson(),
        'receiver': receiver.toReceiverJson(),
        'package': package.toJson(),
        'paymentMethod': _normalizedPaymentMethod,
        'deliverySpeed': deliverySpeed,
        if (couponCode != null && couponCode!.trim().isNotEmpty)
          'couponCode': couponCode!.trim().toUpperCase(),
      };
}
