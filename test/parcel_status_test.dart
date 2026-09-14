import 'package:flutter_test/flutter_test.dart';
import 'package:sungguard/core/constants/app_enums.dart';

void main() {
  group('ParcelStatus', () {
    test('maps every status in the backend CITY_PARCEL_STATUS enum', () {
      const serverStatuses = [
        'REQUESTED',
        'SEARCHING',
        'ACCEPTED',
        'RIDER_ASSIGNED',
        'PICKUP_REACHED',
        'PICKED_UP',
        'AT_WAYPOINT',
        'OUT_FOR_DELIVERY',
        'DROP_REACHED',
        'DELIVERED',
        'DELIVERY_FAILED',
        'RETURN_IN_TRANSIT',
        'RETURNED',
        'CANCELLED',
      ];

      for (final code in serverStatuses) {
        final parsed = ParcelStatus.fromString(code);
        expect(
          parsed.code,
          code,
          reason: '$code fell back to ${parsed.code} instead of mapping',
        );
      }
    });

    test('AT_WAYPOINT no longer degrades to REQUESTED', () {
      final status = ParcelStatus.fromString('AT_WAYPOINT');
      expect(status, ParcelStatus.atWaypoint);
      expect(status, isNot(ParcelStatus.requested));
      expect(status.isMoving, isTrue);
      expect(status.isInRiderCustody, isTrue);
    });

    test('code is the wire value; name is not', () {
      // The timeline indexed _statusOrder with `.name.toUpperCase()`, which
      // produced OUTFORDELIVERY and matched nothing.
      expect(ParcelStatus.outForDelivery.code, 'OUT_FOR_DELIVERY');
      expect(ParcelStatus.outForDelivery.name.toUpperCase(), 'OUTFORDELIVERY');

      const statusOrder = [
        'REQUESTED',
        'SEARCHING',
        'ACCEPTED',
        'RIDER_ASSIGNED',
        'PICKUP_REACHED',
        'PICKED_UP',
        'OUT_FOR_DELIVERY',
        'DROP_REACHED',
        'DELIVERED',
      ];

      // Every multi-word status used to resolve to -1 here.
      for (final status in [
        ParcelStatus.riderAssigned,
        ParcelStatus.pickupReached,
        ParcelStatus.pickedUp,
        ParcelStatus.outForDelivery,
        ParcelStatus.dropReached,
      ]) {
        expect(
          statusOrder.indexOf(status.code),
          greaterThanOrEqualTo(0),
          reason: '${status.name} did not resolve to a milestone index',
        );
      }
    });

    test('unknown values still degrade safely', () {
      expect(ParcelStatus.fromString('SOMETHING_NEW'), ParcelStatus.requested);
      expect(ParcelStatus.fromString(null), ParcelStatus.requested);
    });

    test('isLive matches the backend terminal set', () {
      expect(ParcelStatus.delivered.isLive, isFalse);
      expect(ParcelStatus.returned.isLive, isFalse);
      expect(ParcelStatus.cancelled.isLive, isFalse);
      expect(ParcelStatus.atWaypoint.isLive, isTrue);
      expect(ParcelStatus.deliveryFailed.isLive, isTrue);
    });

    test('custody set mirrors CITY_PARCEL_IN_CUSTODY_STATUSES', () {
      final inCustody = ParcelStatus.values
          .where((s) => s.isInRiderCustody)
          .map((s) => s.code)
          .toSet();

      expect(inCustody, {
        'PICKED_UP',
        'AT_WAYPOINT',
        'OUT_FOR_DELIVERY',
        'DROP_REACHED',
        'DELIVERY_FAILED',
        'RETURN_IN_TRANSIT',
      });
    });
  });
}
