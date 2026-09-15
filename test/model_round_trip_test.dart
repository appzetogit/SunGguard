import 'package:flutter_test/flutter_test.dart';
import 'package:sungguard/core/constants/app_enums.dart';
import 'package:sungguard/features/auth/data/models/user_model.dart';
import 'package:sungguard/features/auth/presentation/bloc/auth_state.dart';
import 'package:sungguard/features/profile/data/models/user_address_model.dart';
import 'package:sungguard/features/tracking/data/models/parcel_detail_model.dart';

void main() {
  group('UserAddressModel', () {
    test('sends coordinates as location{lat,lng}, the schema shape', () {
      const address = UserAddressModel(
        id: '507f1f77bcf86cd799439011',
        label: 'Home',
        fullAddress: '12 Ring Road',
        line: 'Flat 4B',
        landmark: 'By the post office',
        city: 'Indore',
        lat: 22.7196,
        lng: 75.8577,
        placeId: 'ChIJabc',
        formattedAddress: '12 Ring Road, Indore, MP',
      );

      final json = address.toApiJson();

      expect(json['location'], {'lat': 22.7196, 'lng': 75.8577});
      expect(json['placeId'], 'ChIJabc');
      expect(json['formattedAddress'], '12 Ring Road, Indore, MP');
      // The enum is home|work|other; a capitalised label fails validation.
      expect(json['label'], 'home');
      expect(json['_id'], '507f1f77bcf86cd799439011');
    });

    test('omits a client-generated id the server would reject', () {
      const address = UserAddressModel(
        id: 'addr_1717171717',
        label: 'Work',
        fullAddress: '44 MG Road',
        line: '',
        landmark: '',
      );

      expect(address.toApiJson().containsKey('_id'), isFalse);
    });

    test('omits location entirely when unpinned', () {
      const address = UserAddressModel(
        id: '',
        label: 'Other',
        fullAddress: '44 MG Road',
        line: '',
        landmark: '',
      );

      expect(address.toApiJson().containsKey('location'), isFalse);
      expect(address.isBookable, isFalse);
    });

    test('reads coordinates back from nested location', () {
      final address = UserAddressModel.fromJson({
        '_id': 'x',
        'label': 'home',
        'fullAddress': '12 Ring Road',
        'location': {'lat': 22.7, 'lng': 75.8},
      });

      expect(address.lat, 22.7);
      expect(address.lng, 75.8);
      expect(address.isBookable, isTrue);
    });

    test('still reads flat lat/lng from older rows', () {
      final address = UserAddressModel.fromJson({
        'fullAddress': '12 Ring Road',
        'lat': 1.5,
        'lng': 2.5,
      });

      expect(address.lat, 1.5);
      expect(address.lng, 2.5);
    });
  });

  group('ParcelDetailModel', () {
    Map<String, dynamic> trackingBody() => {
          'parcel': {
            '_id': 'p1',
            'referenceId': 'CP-001',
            'status': 'OUT_FOR_DELIVERY',
            'paymentMethod': 'UPI',
            'paymentStatus': 'PENDING',
            // Backend shape: models/cityParcel.js returnLeg + attemptHistory.
            'returnLeg': {'status': 'NONE', 'customerChoice': 'NONE'},
            'attemptHistory': [
              {'attemptNo': 1, 'outcome': 'NO_ANSWER'},
            ],
            'codCollection': {'amount': 120, 'status': 'COLLECT_PENDING'},
            'razorpayOrderId': 'order_9',
            'pickupAddress': {
              'fullAddress': 'A',
              'lat': 22.7,
              'lng': 75.8,
            },
            'dropAddress': {
              'fullAddress': 'B',
              'location': {
                'coordinates': [75.9, 22.8],
              },
            },
          },
          'timeline': [],
        };

    test('captures payment and return fields the app used to drop', () {
      final parcel = ParcelDetailModel.fromJson(trackingBody());

      expect(parcel.paymentMethod, 'UPI');
      expect(parcel.paymentStatus, 'PENDING');
      expect(parcel.returnStatus, 'NONE');
      expect(parcel.deliveryAttempts, 1);
      expect(parcel.codAmount, 120);
      expect(parcel.razorpayOrderId, 'order_9');
    });

    test('reads GeoJSON [lng, lat] in the right order', () {
      final parcel = ParcelDetailModel.fromJson(trackingBody());
      expect(parcel.dropLat, 22.8);
      expect(parcel.dropLng, 75.9);
    });

    test('a socket status update preserves every coordinate', () {
      final parcel = ParcelDetailModel.fromJson(trackingBody());
      final updated = parcel.copyWith(status: ParcelStatus.dropReached);

      // The old hand-rolled rebuild dropped these, blanking the map.
      expect(updated.status, ParcelStatus.dropReached);
      expect(updated.pickupLat, parcel.pickupLat);
      expect(updated.pickupLng, parcel.pickupLng);
      expect(updated.dropLat, parcel.dropLat);
      expect(updated.dropLng, parcel.dropLng);
      expect(updated.referenceId, 'CP-001');
    });

    test('awaitingPayment identifies an unpaid online booking', () {
      final body = trackingBody();
      (body['parcel'] as Map)['status'] = 'REQUESTED';
      expect(ParcelDetailModel.fromJson(body).awaitingPayment, isTrue);
    });

    test('a COD booking is never awaiting payment', () {
      final body = trackingBody();
      (body['parcel'] as Map)['status'] = 'REQUESTED';
      (body['parcel'] as Map)['paymentMethod'] = 'COD';
      expect(ParcelDetailModel.fromJson(body).awaitingPayment, isFalse);
    });
  });

  group('UserModel', () {
    test('carries the avatar the server already returned', () {
      final user = UserModel.fromJson({
        '_id': 'u1',
        'name': 'Ravi',
        'phone': '9876543210',
        'avatar': 'https://cdn.example/a.png',
      });

      expect(user.avatar, 'https://cdn.example/a.png');
      expect(user.toJson()['avatar'], 'https://cdn.example/a.png');
    });

    test('defaults to an empty avatar rather than null', () {
      expect(UserModel.fromJson({'_id': 'u1'}).avatar, '');
    });
  });

  group('AuthState', () {
    test('can clear the user on sign-out', () {
      const user = UserModel(
        id: 'u1',
        name: 'Ravi',
        phone: '9876543210',
        role: 'customer',
      );
      const state = AuthState(isAuthenticated: true, user: user);

      // `user ?? this.user` made this impossible, so a stale profile survived.
      final cleared = state.copyWith(isAuthenticated: false, user: null);
      expect(cleared.user, isNull);
    });

    test('leaves the user alone when not named', () {
      const user = UserModel(
        id: 'u1',
        name: 'Ravi',
        phone: '9876543210',
        role: 'customer',
      );
      const state = AuthState(isAuthenticated: true, user: user);

      expect(state.copyWith(isLoading: true).user, user);
    });
  });
}
