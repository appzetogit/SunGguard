import 'package:intl/intl.dart';
import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/waybill_item_entity.dart';

class WaybillItemModel extends WaybillItemEntity {
  const WaybillItemModel({
    required super.id,
    required super.referenceId,
    required super.status,
    required super.pickupAddress,
    required super.dropAddress,
    required super.formattedTime,
    super.kind = 'local',
    super.amount = 0.0,
    super.createdAt,
  });

  factory WaybillItemModel.fromJson(Map<String, dynamic> json, {String kind = 'local'}) {
    final pickup = json['pickupAddress'];
    final drop = json['dropAddress'];
    final pickupStr = (pickup is Map ? pickup['fullAddress'] : pickup) ?? 'Pickup Point';
    final dropStr = (drop is Map ? drop['fullAddress'] : drop) ?? 'Drop Point';

    String fmtTime = 'Recent';
    DateTime? parsedDt;
    final dateRaw = json['deliveryEta'] ?? json['deliveredAt'] ?? json['createdAt'] ?? json['updatedAt'];
    if (dateRaw != null) {
      try {
        parsedDt = DateTime.parse(dateRaw.toString()).toLocal();
        fmtTime = DateFormat('dd MMM yyyy, hh:mm a').format(parsedDt).toLowerCase();
      } catch (_) {
        fmtTime = dateRaw.toString();
      }
    }

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

    return WaybillItemModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      referenceId: json['referenceId']?.toString() ?? json['waybill']?.toString() ?? 'CP-WAYBILL',
      status: ParcelStatus.fromString(json['status']?.toString()),
      pickupAddress: pickupStr.toString(),
      dropAddress: dropStr.toString(),
      formattedTime: fmtTime,
      kind: kind,
      amount: fareAmount,
      createdAt: parsedDt,
    );
  }
}
