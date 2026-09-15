import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// What the gateway handed back after a checkout attempt.
///
/// A signature triple is the only proof the money actually moved — the server
/// verifies it with an HMAC only Razorpay can produce, and refuses to dispatch
/// a rider without it.
class RazorpayResult {
  final bool success;
  final String? orderId;
  final String? paymentId;
  final String? signature;
  final String? message;

  /// True when the customer dismissed the sheet rather than the payment
  /// failing. Worth distinguishing: a cancellation is not an error to shout
  /// about, it just leaves the booking awaiting payment.
  final bool cancelled;

  const RazorpayResult({
    required this.success,
    this.orderId,
    this.paymentId,
    this.signature,
    this.message,
    this.cancelled = false,
  });
}

/// Order parameters as returned by the backend's `razorpay` block on
/// `POST /city-parcel/create` and `POST /parcel/create`.
class RazorpayOrder {
  final String keyId;
  final String orderId;

  /// Already in paise — the server converts, so it must not be multiplied again.
  final int amount;
  final String currency;

  const RazorpayOrder({
    required this.keyId,
    required this.orderId,
    required this.amount,
    this.currency = 'INR',
  });

  static RazorpayOrder? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final keyId = raw['keyId']?.toString() ?? raw['key_id']?.toString() ?? '';
    final orderId =
        raw['orderId']?.toString() ?? raw['order_id']?.toString() ?? '';
    final amount = (raw['amount'] as num?)?.toInt() ?? 0;
    if (keyId.isEmpty || orderId.isEmpty || amount <= 0) return null;
    return RazorpayOrder(
      keyId: keyId,
      orderId: orderId,
      amount: amount,
      currency: raw['currency']?.toString() ?? 'INR',
    );
  }
}

/// Opens Razorpay checkout and resolves once the customer is done with it.
///
/// The plugin is callback-based and one instance can only serve one checkout
/// at a time, so a fresh instance is built per call and cleared afterwards.
class RazorpayCheckoutService {
  Future<RazorpayResult> open({
    required RazorpayOrder order,
    required String description,
    String contact = '',
    String email = '',
    String appName = 'SunGguard',
  }) async {
    final completer = Completer<RazorpayResult>();
    final razorpay = Razorpay();

    void finish(RazorpayResult result) {
      if (!completer.isCompleted) completer.complete(result);
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      finish(
        RazorpayResult(
          success: true,
          orderId: r.orderId ?? order.orderId,
          paymentId: r.paymentId,
          signature: r.signature,
        ),
      );
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      // Code 2 is the plugin's "cancelled by user".
      final isCancel = r.code == Razorpay.PAYMENT_CANCELLED;
      finish(
        RazorpayResult(
          success: false,
          cancelled: isCancel,
          message: isCancel ? null : (r.message ?? 'Payment failed'),
        ),
      );
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
      // The customer left for a wallet app. Nothing is confirmed yet; the
      // booking stays awaiting payment and can be retried.
      finish(
        const RazorpayResult(
          success: false,
          cancelled: true,
        ),
      );
    });

    try {
      razorpay.open({
        'key': order.keyId,
        'order_id': order.orderId,
        'amount': order.amount,
        'currency': order.currency,
        'name': appName,
        'description': description,
        'prefill': {'contact': contact, 'email': email},
        'theme': {'color': '#059669'},
        'retry': {'enabled': true, 'max_count': 1},
      });
    } catch (e) {
      debugPrint('❌ Razorpay open failed: $e');
      finish(
        RazorpayResult(
          success: false,
          message: 'Could not open the payment screen',
        ),
      );
    }

    final result = await completer.future;
    // Give the platform channel a beat to deliver any trailing callback
    // before tearing the instance down.
    Future.delayed(const Duration(seconds: 1), razorpay.clear);
    return result;
  }
}
