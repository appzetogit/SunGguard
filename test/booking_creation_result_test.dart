import 'package:flutter_test/flutter_test.dart';
import 'package:sungguard/features/booking/data/models/booking_creation_result.dart';

/// The two fields whose loss stranded every online booking:
/// `requiresPayment` and the `razorpay` order block.
void main() {
  group('BookingCreationResult', () {
    test('COD response is confirmed outright, with no payment step', () {
      final result = BookingCreationResult.fromJson({
        'parcel': {'_id': 'abc123', 'status': 'SEARCHING'},
        'requiresPayment': false,
      });

      expect(result.parcelId, 'abc123');
      expect(result.requiresPayment, isFalse);
      expect(result.isPayable, isFalse);
      expect(result.isBrokenPaymentSetup, isFalse);
    });

    test('online response exposes the gateway order', () {
      final result = BookingCreationResult.fromJson({
        'parcel': {'_id': 'abc123', 'status': 'REQUESTED'},
        'requiresPayment': true,
        'razorpay': {
          'keyId': 'rzp_test_key',
          'orderId': 'order_XYZ',
          'amount': 12500,
          'currency': 'INR',
        },
      });

      expect(result.isPayable, isTrue);
      expect(result.razorpayOrder!.keyId, 'rzp_test_key');
      expect(result.razorpayOrder!.orderId, 'order_XYZ');
      // Already paise — must not be multiplied again on the client.
      expect(result.razorpayOrder!.amount, 12500);
    });

    test('unwraps a result envelope', () {
      final result = BookingCreationResult.fromJson({
        'result': {
          'parcel': {'_id': 'nested1'},
          'requiresPayment': true,
          'razorpay': {
            'keyId': 'k',
            'orderId': 'o',
            'amount': 100,
          },
        },
      });

      expect(result.parcelId, 'nested1');
      expect(result.isPayable, isTrue);
    });

    test('reads a parcel returned at the top level', () {
      final result = BookingCreationResult.fromJson({'_id': 'flat1'});
      expect(result.parcelId, 'flat1');
    });

    test('payment required but no usable order is flagged, not ignored', () {
      final result = BookingCreationResult.fromJson({
        'parcel': {'_id': 'abc'},
        'requiresPayment': true,
      });

      expect(result.isPayable, isFalse);
      // Must not read as success: the parcel would sit unbroadcast forever.
      expect(result.isBrokenPaymentSetup, isTrue);
    });

    test('an order missing its amount is not usable', () {
      final result = BookingCreationResult.fromJson({
        'parcel': {'_id': 'abc'},
        'requiresPayment': true,
        'razorpay': {'keyId': 'k', 'orderId': 'o', 'amount': 0},
      });

      expect(result.razorpayOrder, isNull);
      expect(result.isBrokenPaymentSetup, isTrue);
    });

    test('an empty body yields no parcel id rather than a fabricated one', () {
      expect(BookingCreationResult.fromJson(null).parcelId, isEmpty);
      expect(BookingCreationResult.fromJson({}).parcelId, isEmpty);
    });
  });
}
