import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_enums.dart';

class ParcelSummaryEntity extends Equatable {
  final String id;
  final String referenceId;
  final ParcelStatus status;
  final String pickupAddress;
  final String dropAddress;
  final String? pickedUpAt;
  final String? deliveryEta;
  final double distanceKm;
  final double amount;
  final String kind; // 'local' | 'outstation'

  const ParcelSummaryEntity({
    required this.id,
    required this.referenceId,
    required this.status,
    required this.pickupAddress,
    required this.dropAddress,
    this.pickedUpAt,
    this.deliveryEta,
    required this.distanceKm,
    required this.amount,
    this.kind = 'local',
  });

  @override
  List<Object?> get props => [
        id,
        referenceId,
        status,
        pickupAddress,
        dropAddress,
        pickedUpAt,
        deliveryEta,
        distanceKm,
        amount,
        kind,
      ];
}
