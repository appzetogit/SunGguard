import 'package:flutter_test/flutter_test.dart';
import 'package:sungguard/features/booking/data/models/city_parcel_booking_request.dart';

/// Guards the request shape against the backend's Joi schema
/// (`app/validation/cityParcelValidation.js`).
void main() {
  group('AddressData', () {
    test('always emits lat/lng, which the server marks required', () {
      const address = AddressData(
        fullAddress: '12 Ring Road, Indore',
        lat: 22.7196,
        lng: 75.8577,
      );

      final json = address.toJson();

      expect(json['lat'], 22.7196);
      expect(json['lng'], 75.8577);
      expect(json.containsKey('lat'), isTrue);
      expect(json.containsKey('lng'), isTrue);
    });

    test('folds line and landmark into addressNote', () {
      const address = AddressData(
        fullAddress: '12 Ring Road, Indore',
        line: 'Flat 4B',
        landmark: 'Opposite the post office',
        lat: 22.7,
        lng: 75.8,
      );

      final json = address.toJson();

      // The schema accepts only fullAddress/lat/lng/addressNote and strips
      // everything else, so line and landmark must not be sent as-is.
      expect(json.containsKey('line'), isFalse);
      expect(json.containsKey('landmark'), isFalse);
      expect(json['addressNote'], 'Opposite the post office, Flat 4B');
    });

    test('caps addressNote at the schema maximum of 200 characters', () {
      final address = AddressData(
        fullAddress: '12 Ring Road, Indore',
        landmark: 'x' * 400,
        lat: 22.7,
        lng: 75.8,
      );

      expect((address.toJson()['addressNote'] as String).length, 200);
    });

    test('omits addressNote entirely when there is nothing to say', () {
      const address = AddressData(
        fullAddress: '12 Ring Road, Indore',
        lat: 22.7,
        lng: 75.8,
      );

      expect(address.toJson().containsKey('addressNote'), isFalse);
    });

    test('isComplete requires both coordinates and a usable address', () {
      const noCoords = AddressData(fullAddress: '12 Ring Road, Indore');
      const tooShort = AddressData(fullAddress: 'abc', lat: 1, lng: 2);
      const ok = AddressData(fullAddress: '12 Ring Road', lat: 1, lng: 2);

      expect(noCoords.isComplete, isFalse);
      expect(tooShort.isComplete, isFalse);
      expect(ok.isComplete, isTrue);
    });
  });

  group('PersonData', () {
    test('receiver payload carries altPhone and allowAlternate', () {
      const receiver = PersonData(
        name: 'Asha',
        phone: '98765 43210',
        altPhone: '91234-56789',
        allowAlternate: true,
      );

      final json = receiver.toReceiverJson();

      expect(json['phone'], '9876543210');
      expect(json['altPhone'], '9123456789');
      expect(json['allowAlternate'], isTrue);
    });

    test('omits altPhone when blank rather than sending an empty string', () {
      const receiver = PersonData(name: 'Asha', phone: '9876543210');

      expect(receiver.toReceiverJson().containsKey('altPhone'), isFalse);
    });

    test('sender payload stays name and phone only', () {
      const sender = PersonData(
        name: 'Ravi',
        phone: '9876543210',
        altPhone: '9123456789',
        allowAlternate: true,
      );

      // The server's sender schema rejects unknown keys, so the extra
      // receiver-only fields must not leak into it.
      expect(sender.toJson().keys.toSet(), {'name', 'phone'});
    });
  });

  group('PackageData', () {
    test('includes declaredValue only when set', () {
      const withValue = PackageData(
        packageType: 'document',
        weightKg: 1.0,
        declaredValue: 2500,
      );
      const withoutValue = PackageData(packageType: 'document', weightKg: 1.0);

      expect(withValue.toJson()['declaredValue'], 2500);
      expect(withoutValue.toJson().containsKey('declaredValue'), isFalse);
    });
  });

  group('CityParcelBookingRequest', () {
    CityParcelBookingRequest build({
      String paymentMethod = 'UPI',
      String deliverySpeed = 'normal',
    }) {
      return CityParcelBookingRequest(
        pickupAddress: const AddressData(
          fullAddress: '12 Ring Road, Indore',
          lat: 22.7,
          lng: 75.8,
        ),
        dropAddress: const AddressData(
          fullAddress: '44 MG Road, Indore',
          lat: 22.8,
          lng: 75.9,
        ),
        sender: const PersonData(name: 'Ravi', phone: '9876543210'),
        receiver: const PersonData(name: 'Asha', phone: '9123456789'),
        package: const PackageData(packageType: 'document', weightKg: 0.5),
        paymentMethod: paymentMethod,
        deliverySpeed: deliverySpeed,
      );
    }

    test('normalises CASH to the COD the server enum accepts', () {
      expect(build(paymentMethod: 'cash').toJson()['paymentMethod'], 'COD');
    });

    test('passes WALLET through, which the server accepts', () {
      expect(build(paymentMethod: 'WALLET').toJson()['paymentMethod'], 'WALLET');
    });

    test('sends deliverySpeed so express is actually priced', () {
      expect(build(deliverySpeed: 'express').toJson()['deliverySpeed'],
          'express');
    });

    test('top-level keys match the create schema exactly', () {
      expect(build().toJson().keys.toSet(), {
        'pickupAddress',
        'dropAddress',
        'sender',
        'receiver',
        'package',
        'paymentMethod',
        'deliverySpeed',
      });
    });
  });
}
