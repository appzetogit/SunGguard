import 'package:equatable/equatable.dart';

double _d(dynamic v) =>
    (v is num) ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? 0.0);

/// One row of `GET /city-parcel/coupons/available` or `/parcel/coupons/available`.
class AvailableCoupon extends Equatable {
  final String code;
  final String discountType; // 'percentage' | 'fixed'
  final double discountValue;
  final double minOrderValue;
  final String description;

  const AvailableCoupon({
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue = 0,
    this.description = '',
  });

  String get label => discountType == 'percentage'
      ? '$code · ${discountValue.toStringAsFixed(0)}% OFF'
      : '$code · ₹${discountValue.toStringAsFixed(0)} OFF';

  static AvailableCoupon? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final code = raw['code']?.toString() ?? '';
    if (code.isEmpty) return null;
    return AvailableCoupon(
      code: code,
      discountType: raw['discountType']?.toString() ?? 'fixed',
      discountValue: _d(raw['discountValue']),
      minOrderValue: _d(raw['minOrderValue']),
      description: raw['description']?.toString() ?? '',
    );
  }

  /// The client unwraps `result`, not `results`, so both are handled.
  static List<AvailableCoupon> listFrom(dynamic res) {
    final raw = res is List
        ? res
        : (res is Map ? (res['results'] ?? res['result'] ?? res['items']) : null);
    if (raw is! List) return const [];
    return raw.map(fromJson).whereType<AvailableCoupon>().toList();
  }

  @override
  List<Object?> get props => [code, discountType, discountValue, minOrderValue];
}

/// `POST .../coupon/validate` →
/// `{couponId, code, fare, discountAmount, payableFare, taxableDiscount, tax{...}}`.
class AppliedCoupon extends Equatable {
  final String couponId;
  final String code;
  final double fare;
  final double discountAmount;
  final double payableFare;
  final double taxableDiscount;
  final double taxAmount;
  final double taxPercent;

  const AppliedCoupon({
    required this.couponId,
    required this.code,
    required this.fare,
    required this.discountAmount,
    required this.payableFare,
    this.taxableDiscount = 0,
    this.taxAmount = 0,
    this.taxPercent = 0,
  });

  static AppliedCoupon fromJson(dynamic res) {
    final m = res is Map ? res : const {};
    final tax = m['tax'] is Map ? m['tax'] as Map : const {};
    return AppliedCoupon(
      couponId: m['couponId']?.toString() ?? '',
      code: m['code']?.toString() ?? '',
      fare: _d(m['fare']),
      discountAmount: _d(m['discountAmount']),
      payableFare: _d(m['payableFare']),
      taxableDiscount: m['taxableDiscount'] != null
          ? _d(m['taxableDiscount'])
          : _d(m['discountAmount']),
      taxAmount: _d(tax['amount']),
      taxPercent: _d(tax['percent']),
    );
  }

  @override
  List<Object?> get props => [couponId, code, fare, discountAmount, payableFare];
}
