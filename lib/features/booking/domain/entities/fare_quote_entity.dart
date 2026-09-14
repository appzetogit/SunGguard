import 'package:equatable/equatable.dart';

class FareQuoteEntity extends Equatable {
  final double baseFare;
  final double distanceFare;
  final double weightFare;

  /// GST amount (`tax.amount` / `fareBreakdown.gstAmount`).
  final double tax;
  final double total;
  final double distanceKm;
  final String estimatedTime;

  final double platformCharge;
  final double expressCharge;
  final double gstPercent;
  final double taxableAmount;
  final bool minFareApplied;
  final int etaMinutes;

  const FareQuoteEntity({
    required this.baseFare,
    required this.distanceFare,
    required this.weightFare,
    required this.tax,
    required this.total,
    required this.distanceKm,
    required this.estimatedTime,
    this.platformCharge = 0,
    this.expressCharge = 0,
    this.gstPercent = 0,
    this.taxableAmount = 0,
    this.minFareApplied = false,
    this.etaMinutes = 0,
  });

  @override
  List<Object?> get props => [
        baseFare,
        distanceFare,
        weightFare,
        tax,
        total,
        distanceKm,
        estimatedTime,
        platformCharge,
        expressCharge,
        gstPercent,
        taxableAmount,
        minFareApplied,
        etaMinutes,
      ];
}
