import '../../../../core/services/razorpay_checkout_service.dart';

/// What `POST /city-parcel/create` and `POST /parcel/create` actually return.
///
/// The app used to read only `parcel._id`. For anything other than COD the
/// backend replies `requiresPayment: true` plus an open Razorpay order, and
/// deliberately leaves the parcel at REQUESTED — unbroadcast, with no rider
/// dispatched — until a verified signature comes back. Discarding these two
/// fields is what stranded every online booking.
class BookingCreationResult {
  final String parcelId;
  final bool requiresPayment;
  final RazorpayOrder? razorpayOrder;

  const BookingCreationResult({
    required this.parcelId,
    this.requiresPayment = false,
    this.razorpayOrder,
  });

  bool get isPayable => requiresPayment && razorpayOrder != null;

  /// Server said payment is needed but sent no usable order. Treated as a
  /// failure rather than a silent success — the booking cannot proceed.
  bool get isBrokenPaymentSetup => requiresPayment && razorpayOrder == null;

  static BookingCreationResult fromJson(dynamic res) {
    final data = (res is Map) ? res : const {};
    final root = (data['result'] is Map)
        ? data['result'] as Map
        : (data['data'] is Map ? data['data'] as Map : data);

    final parcel = (root['parcel'] is Map) ? root['parcel'] as Map : root;

    final id = parcel['_id']?.toString() ?? parcel['id']?.toString() ?? '';

    return BookingCreationResult(
      parcelId: id,
      requiresPayment: root['requiresPayment'] == true,
      razorpayOrder: RazorpayOrder.fromJson(root['razorpay']),
    );
  }
}
