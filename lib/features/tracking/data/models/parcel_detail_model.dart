import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/parcel_detail_entity.dart';

/// `GET /city-parcel/track/:id` → `{parcel, timeline}`; also used for the
/// cancel / verify responses, where `parcel` is NOT populated (refs are
/// plain ObjectId strings), so every nested read is type-checked.
class ParcelDetailModel extends ParcelDetailEntity {
  const ParcelDetailModel({
    required super.id,
    required super.referenceId,
    required super.status,
    required super.pickupAddress,
    required super.dropAddress,
    super.pickupLat,
    super.pickupLng,
    super.dropLat,
    super.dropLng,
    super.riderLat,
    super.riderLng,
    required super.senderName,
    required super.senderPhone,
    required super.receiverName,
    required super.receiverPhone,
    required super.packageType,
    required super.weightKg,
    required super.amount,
    super.rider,
    super.handoverCode,
    super.createdAt,
    super.timeline = const [],
    super.paymentMethod,
    super.paymentStatus,
    super.returnStatus,
    super.customerChoice,
    super.deliveryAttempts,
    super.deliveryDeadline,
    super.codAmount,
    super.razorpayOrderId,
  });

  static Map<String, dynamic>? _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  static double? _num(dynamic v) => v is num ? v.toDouble() : null;

  static String _addressText(dynamic addr) {
    if (addr is Map) {
      return addr['fullAddress']?.toString() ?? addr['line']?.toString() ?? '';
    }
    return addr is String ? addr : '';
  }

  /// `[lat, lng]` from `{lat,lng}` or GeoJSON `{location:{coordinates:[lng,lat]}}`.
  static List<double?> _coords(dynamic addr) {
    if (addr is! Map) return const [null, null];
    double? lat = _num(addr['lat']) ?? _num(addr['latitude']);
    double? lng = _num(addr['lng']) ?? _num(addr['longitude']);
    final loc = addr['location'];
    if ((lat == null || lng == null) && loc is Map && loc['coordinates'] is List) {
      final c = loc['coordinates'] as List;
      if (c.length >= 2) {
        lng = _num(c[0]);
        lat = _num(c[1]);
      }
    }
    return [lat, lng];
  }

  factory ParcelDetailModel.fromJson(Map<String, dynamic> rawJson) {
    final root = _map(rawJson['result']) ?? _map(rawJson['data']) ?? rawJson;
    final parcel = _map(root['parcel']) ?? root;

    final pickup = parcel['pickupAddress'];
    final drop = parcel['dropAddress'];
    final pickupStr = _addressText(pickup);
    final dropStr = _addressText(drop);

    final receiver = _map(parcel['receiver']);
    final sender = _map(parcel['sender']);
    final pkg = _map(parcel['package']);

    // What the customer pays: payableFare (after coupon), else fare.
    double amount = 0.0;
    final payable = _num(parcel['payableFare']);
    if (payable != null && payable > 0) {
      amount = payable;
    } else if (parcel['fare'] is num) {
      amount = (parcel['fare'] as num).toDouble();
    } else if (parcel['fare'] is Map) {
      final fare = parcel['fare'] as Map;
      amount = _num(fare['total']) ?? _num(fare['fare']) ?? 0.0;
    } else {
      amount = _num(parcel['amount']) ?? 0.0;
    }

    final riderData =
        _map(parcel['deliveryPartnerId']) ?? _map(parcel['assignedRider']);
    RiderInfoEntity? rider;
    if (riderData != null && riderData['name'] != null) {
      rider = RiderInfoEntity(
        name: riderData['name']?.toString() ?? '',
        phone: riderData['phone']?.toString() ?? '',
        vehicleNumber: riderData['vehicleNumber']?.toString(),
        vehicleType: riderData['vehicleType']?.toString(),
      );
    }

    final rawTimeline = root['timeline'] is List
        ? root['timeline'] as List
        : (parcel['timeline'] is List ? parcel['timeline'] as List : const []);
    final timeline = rawTimeline.whereType<Map>().map((m) {
      return TrackingTimelineEventEntity(
        status: m['status']?.toString() ?? '',
        at: m['at']?.toString() ?? m['createdAt']?.toString(),
        note: m['note']?.toString(),
        actor: m['actor']?.toString(),
      );
    }).toList();

    final p = _coords(pickup);
    final d = _coords(drop);
    final r = _coords(riderData);

    final returnLeg = _map(parcel['returnLeg']);
    final attempts = parcel['attemptHistory'];
    final cod = _map(parcel['codCollection']);

    return ParcelDetailModel(
      id: parcel['_id']?.toString() ?? parcel['id']?.toString() ?? '',
      referenceId: parcel['referenceId']?.toString() ?? 'CP-WAYBILL',
      status: ParcelStatus.fromString(parcel['status']?.toString()),
      pickupAddress: pickupStr.isNotEmpty ? pickupStr : 'Pickup Location',
      dropAddress: dropStr.isNotEmpty ? dropStr : 'Drop Destination',
      pickupLat: p[0],
      pickupLng: p[1],
      dropLat: d[0],
      dropLng: d[1],
      riderLat: r[0],
      riderLng: r[1],
      senderName: sender?['name']?.toString() ?? 'Sender',
      senderPhone: sender?['phone']?.toString() ?? '',
      receiverName: receiver?['name']?.toString() ?? 'Receiver',
      receiverPhone: receiver?['phone']?.toString() ?? '',
      packageType: pkg?['packageType']?.toString() ?? 'Documents',
      weightKg: _num(pkg?['weightKg']) ?? 0.5,
      amount: amount,
      rider: rider,
      // Codes are stored hashed; only mock mode ever returns `devCode`.
      handoverCode: parcel['devCode']?.toString(),
      createdAt: parcel['createdAt']?.toString(),
      timeline: timeline,
      paymentMethod: parcel['paymentMethod']?.toString() ?? '',
      paymentStatus: parcel['paymentStatus']?.toString() ?? '',
      // Backend keeps these under returnLeg / attemptHistory.
      returnStatus: returnLeg?['status']?.toString() ?? '',
      customerChoice: returnLeg?['customerChoice']?.toString() ?? '',
      deliveryAttempts: attempts is List ? attempts.length : 0,
      deliveryDeadline: parcel['deliveryDeadline']?.toString(),
      codAmount: _num(cod?['amount']) ?? 0.0,
      razorpayOrderId: parcel['razorpayOrderId']?.toString(),
    );
  }
}
