import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/parcel_summary_entity.dart';

class ParcelSummaryModel extends ParcelSummaryEntity {
  const ParcelSummaryModel({
    required super.id,
    required super.referenceId,
    required super.status,
    required super.pickupAddress,
    required super.dropAddress,
    super.pickedUpAt,
    super.deliveryEta,
    required super.distanceKm,
    required super.amount,
    super.kind = 'local',
  });

  factory ParcelSummaryModel.fromJson(Map<String, dynamic> json, {String kind = 'local'}) {
    final pickup = json['pickupAddress'];
    final drop = json['dropAddress'];
    final pickupStr = (pickup is Map ? pickup['fullAddress'] : pickup) ?? 'Pickup Point';
    final dropStr = (drop is Map ? drop['fullAddress'] : drop) ??
        json['destinationCity'] ??
        'Drop Point';

    double fareAmount = 0.0;
    if (json['fare'] is num) {
      fareAmount = (json['fare'] as num).toDouble();
    } else if (json['fare'] is Map) {
      fareAmount = (json['fare']['total'] as num?)?.toDouble() ??
          (json['fare']['fare'] as num?)?.toDouble() ??
          0.0;
    } else if (json['amount'] is num) {
      fareAmount = (json['amount'] as num).toDouble();
    }

    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final ref = json['referenceId']?.toString() ??
        json['trackingNumber']?.toString() ??
        json['waybill']?.toString() ??
        (id.length >= 8 ? 'SG-${id.substring(id.length - 6).toUpperCase()}' : 'WAYBILL');

    final dist = (json['distanceKm'] as num?)?.toDouble() ??
        (json['distance'] as num?)?.toDouble() ??
        0.0;

    final statusRaw = json['status']?.toString() ??
        json['workflowStatus']?.toString() ??
        json['orderStatus']?.toString();

    return ParcelSummaryModel(
      id: id,
      referenceId: ref,
      status: ParcelStatus.fromString(statusRaw),
      pickupAddress: pickupStr.toString(),
      dropAddress: dropStr.toString(),
      pickedUpAt: json['pickedUpAt']?.toString() ?? json['createdAt']?.toString(),
      deliveryEta: json['deliveryEta']?.toString() ?? json['expectedDeliveryDate']?.toString(),
      distanceKm: dist,
      amount: fareAmount,
      kind: kind,
    );
  }
}
