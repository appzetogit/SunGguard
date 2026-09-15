import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_enums.dart';

class WaybillItemEntity extends Equatable {
  final String id;
  final String referenceId;
  final ParcelStatus status;
  final String pickupAddress;
  final String dropAddress;
  final String formattedTime;
  final String kind; // 'local' | 'outstation'
  final double amount;
  final DateTime? createdAt;

  const WaybillItemEntity({
    required this.id,
    required this.referenceId,
    required this.status,
    required this.pickupAddress,
    required this.dropAddress,
    required this.formattedTime,
    this.kind = 'local',
    this.amount = 0.0,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        referenceId,
        status,
        pickupAddress,
        dropAddress,
        formattedTime,
        kind,
        amount,
        createdAt,
      ];
}
