import '../../domain/entities/fare_quote_entity.dart';

/// `POST /city-parcel/calculate-fare` →
/// `{distanceKm, fare, fareBreakdown{...}, tax{percent,amount,...}, etaMinutes, deliveryEta}`.
class FareQuoteModel extends FareQuoteEntity {
  const FareQuoteModel({
    required super.baseFare,
    required super.distanceFare,
    required super.weightFare,
    required super.tax,
    required super.total,
    required super.distanceKm,
    required super.estimatedTime,
    super.platformCharge,
    super.expressCharge,
    super.gstPercent,
    super.taxableAmount,
    super.minFareApplied,
    super.etaMinutes,
  });

  static double _d(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? 0.0);

  factory FareQuoteModel.fromJson(Map<String, dynamic> rawJson) {
    final json = rawJson['result'] is Map
        ? Map<String, dynamic>.from(rawJson['result'] as Map)
        : rawJson;

    final breakdown = json['fareBreakdown'] is Map
        ? Map<String, dynamic>.from(json['fareBreakdown'] as Map)
        : json;
    final taxObj = json['tax'] is Map ? json['tax'] as Map : const {};

    final etaMinutes = (json['etaMinutes'] as num?)?.toInt() ?? 0;

    return FareQuoteModel(
      baseFare: _d(breakdown['baseFare']),
      distanceFare: _d(breakdown['distanceFare']),
      weightFare: _d(breakdown['weightFare']),
      platformCharge: _d(breakdown['platformCharge']),
      expressCharge: _d(breakdown['expressCharge']),
      tax: taxObj['amount'] != null ? _d(taxObj['amount']) : _d(breakdown['gstAmount']),
      gstPercent: taxObj['percent'] != null ? _d(taxObj['percent']) : _d(breakdown['gstPercent']),
      taxableAmount: taxObj['taxableAmount'] != null
          ? _d(taxObj['taxableAmount'])
          : _d(breakdown['taxableAmount']),
      minFareApplied: breakdown['minFareApplied'] == true,
      total: json['fare'] != null ? _d(json['fare']) : _d(breakdown['fare']),
      distanceKm: _d(json['distanceKm']),
      etaMinutes: etaMinutes,
      estimatedTime: etaMinutes > 0 ? '$etaMinutes minutes' : '',
    );
  }
}
