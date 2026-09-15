import '../../domain/entities/user_address_entity.dart';

class UserAddressModel extends UserAddressEntity {
  const UserAddressModel({
    required super.id,
    required super.label,
    required super.fullAddress,
    required super.line,
    required super.landmark,
    super.city = '',
    super.state = '',
    super.pincode = '',
    super.name = '',
    super.phone = '',
    super.isDefault = false,
    super.lat,
    super.lng,
    super.formattedAddress = '',
    super.placeId = '',
  });

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    // The backend stores coordinates nested under `location`; older rows may
    // carry them flat.
    final location = json['location'];
    double? lat;
    double? lng;
    if (location is Map) {
      lat = (location['lat'] as num?)?.toDouble();
      lng = (location['lng'] as num?)?.toDouble();
    }
    lat ??= (json['lat'] as num?)?.toDouble();
    lng ??= (json['lng'] as num?)?.toDouble();

    return UserAddressModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? json['tag']?.toString() ?? 'Home',
      fullAddress:
          json['fullAddress']?.toString() ?? json['address']?.toString() ?? '',
      line: json['line']?.toString() ?? json['flat']?.toString() ?? '',
      landmark: json['landmark']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
      lat: lat,
      lng: lng,
      formattedAddress: json['formattedAddress']?.toString() ?? '',
      placeId: json['placeId']?.toString() ?? '',
    );
  }

  factory UserAddressModel.fromEntity(UserAddressEntity e) => UserAddressModel(
        id: e.id,
        label: e.label,
        fullAddress: e.fullAddress,
        line: e.line,
        landmark: e.landmark,
        city: e.city,
        state: e.state,
        pincode: e.pincode,
        name: e.name,
        phone: e.phone,
        isDefault: e.isDefault,
        lat: e.lat,
        lng: e.lng,
        formattedAddress: e.formattedAddress,
        placeId: e.placeId,
      );

  static bool isValidObjectId(String id) {
    return RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);
  }

  /// Payload for `PUT /customer/profile`.
  ///
  /// `label` is lowercased because the schema enum is `home|work|other` and a
  /// capitalised value fails Mongoose validation. `location` is what makes a
  /// saved address usable for booking; it was previously never sent.
  ///
  /// `line`, `name`, `phone` and `isDefault` are not in the backend's address
  /// subdocument and are dropped on save — they are still sent so that they
  /// start persisting the moment the schema gains them.
  Map<String, dynamic> toApiJson() => {
        if (id.isNotEmpty && isValidObjectId(id)) '_id': id,
        'label': label.toLowerCase(),
        'fullAddress': fullAddress,
        'line': line,
        if (landmark.isNotEmpty) 'landmark': landmark,
        if (city.isNotEmpty) 'city': city,
        if (state.isNotEmpty) 'state': state,
        if (pincode.isNotEmpty) 'pincode': pincode,
        if (name.isNotEmpty) 'name': name,
        if (phone.isNotEmpty) 'phone': phone,
        if (formattedAddress.isNotEmpty) 'formattedAddress': formattedAddress,
        if (placeId.isNotEmpty) 'placeId': placeId,
        if (lat != null && lng != null) 'location': {'lat': lat, 'lng': lng},
        'isDefault': isDefault,
      };

  Map<String, dynamic> toJson() => toApiJson();
}
