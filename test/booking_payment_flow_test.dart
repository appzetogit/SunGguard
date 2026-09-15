import 'package:flutter_test/flutter_test.dart';
import 'package:sungguard/core/network/api_exceptions.dart';
import 'package:sungguard/core/services/razorpay_checkout_service.dart';
import 'package:sungguard/features/booking/data/models/booking_creation_result.dart';
import 'package:sungguard/features/booking/data/models/city_parcel_booking_request.dart';
import 'package:sungguard/features/booking/data/models/coupon_models.dart';
import 'package:sungguard/features/booking/data/models/zone_check_model.dart';
import 'package:sungguard/features/booking/domain/entities/fare_quote_entity.dart';
import 'package:sungguard/features/booking/domain/repositories/booking_repository.dart';
import 'package:sungguard/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:sungguard/features/booking/presentation/bloc/booking_event.dart';
import 'package:sungguard/features/booking/presentation/bloc/booking_state.dart';

class _FakeBookingRepository implements BookingRepository {
  BookingCreationResult createResult = const BookingCreationResult(
    parcelId: 'p1',
  );
  Object? createError;
  Object? verifyError;
  Object? fareError;
  ZoneCheckModel zone = const ZoneCheckModel(gated: false, covered: true);

  int verifyCalls = 0;
  Map<String, String>? lastVerifyArgs;
  String? lastFareSpeed;

  @override
  Future<FareQuoteEntity> calculateFare({
    required AddressData pickup,
    required AddressData drop,
    required PackageData package,
    String deliverySpeed = 'normal',
  }) async {
    lastFareSpeed = deliverySpeed;
    if (fareError != null) throw fareError!;
    return const FareQuoteEntity(
      baseFare: 30,
      distanceFare: 20,
      weightFare: 5,
      tax: 0,
      total: 55,
      distanceKm: 4.2,
      estimatedTime: '30 minutes',
    );
  }

  @override
  Future<BookingCreationResult> createBooking(
    CityParcelBookingRequest request,
  ) async {
    if (createError != null) throw createError!;
    return createResult;
  }

  @override
  Future<BookingCreationResult> verifyPayment({
    required String parcelId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    verifyCalls++;
    lastVerifyArgs = {
      'parcelId': parcelId,
      'orderId': razorpayOrderId,
      'paymentId': razorpayPaymentId,
      'signature': razorpaySignature,
    };
    if (verifyError != null) throw verifyError!;
    return BookingCreationResult(parcelId: parcelId);
  }

  @override
  Future<ZoneCheckModel> checkZone({
    required double lat,
    required double lng,
  }) async =>
      zone;

  @override
  Future<List<AvailableCoupon>> getAvailableCoupons({double? fare}) async =>
      const [];

  @override
  Future<AppliedCoupon> validateCoupon({
    required AddressData pickup,
    required AddressData drop,
    required PackageData package,
    required String deliverySpeed,
    required String couponCode,
  }) async =>
      AppliedCoupon(
        couponId: 'c1',
        code: couponCode,
        fare: 55,
        discountAmount: 5,
        payableFare: 50,
      );

  @override
  Future<bool> checkServiceability({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async =>
      true;
}

void main() {
  late _FakeBookingRepository repo;
  late BookingBloc bloc;

  const pickup = AddressData(
    fullAddress: '12 Ring Road, Indore',
    lat: 22.7,
    lng: 75.8,
  );
  const drop = AddressData(
    fullAddress: '44 MG Road, Indore',
    lat: 22.8,
    lng: 75.9,
  );

  void seedAddresses() {
    bloc.add(
      const BookingPickupUpdated(
        pickup: pickup,
        sender: PersonData(name: 'Ravi', phone: '9876543210'),
      ),
    );
    bloc.add(
      const BookingDropUpdated(
        drop: drop,
        receiver: PersonData(name: 'Asha', phone: '9123456789'),
      ),
    );
  }

  setUp(() {
    repo = _FakeBookingRepository();
    bloc = BookingBloc(bookingRepository: repo);
  });

  tearDown(() => bloc.close());

  group('COD', () {
    test('confirms immediately — the backend already dispatches a rider',
        () async {
      repo.createResult = const BookingCreationResult(
        parcelId: 'cod1',
        requiresPayment: false,
      );
      seedAddresses();
      bloc.add(const BookingPaymentMethodSelected('COD'));
      bloc.add(BookingSubmitRequested());

      await expectLater(
        bloc.stream.firstWhere(
          (s) => s.paymentStage == BookingPaymentStage.confirmed,
        ),
        completes,
      );
      expect(bloc.state.createdParcelId, 'cod1');
    });
  });

  group('online payment', () {
    test('waits for checkout instead of navigating away', () async {
      repo.createResult = const BookingCreationResult(
        parcelId: 'upi1',
        requiresPayment: true,
        razorpayOrder: RazorpayOrder(
          keyId: 'rzp_test',
          orderId: 'order_1',
          amount: 5500,
        ),
      );
      seedAddresses();
      bloc.add(BookingSubmitRequested());

      await bloc.stream.firstWhere(
        (s) => s.paymentStage == BookingPaymentStage.awaitingCheckout,
      );

      // The parcel exists, but is NOT confirmed: the server has not broadcast
      // it and will not until the signature verifies.
      expect(bloc.state.createdParcelId, 'upi1');
      expect(bloc.state.pendingOrder!.orderId, 'order_1');
      expect(bloc.state.paymentStage,
          isNot(BookingPaymentStage.confirmed));
      expect(bloc.state.isPaymentInFlight, isTrue);
    });

    test('confirms only after the signature verifies', () async {
      seedAddresses();
      bloc.add(
        const BookingVerifyPaymentRequested(
          parcelId: 'upi1',
          razorpayOrderId: 'order_1',
          razorpayPaymentId: 'pay_1',
          razorpaySignature: 'sig_1',
        ),
      );

      await bloc.stream.firstWhere(
        (s) => s.paymentStage == BookingPaymentStage.confirmed,
      );

      expect(repo.verifyCalls, 1);
      expect(repo.lastVerifyArgs, {
        'parcelId': 'upi1',
        'orderId': 'order_1',
        'paymentId': 'pay_1',
        'signature': 'sig_1',
      });
    });

    test('a rejected signature leaves the booking retryable, not dead',
        () async {
      repo.verifyError = const ApiException(
        message: 'Signature verification failed',
        statusCode: 400,
      );
      repo.createResult = const BookingCreationResult(
        parcelId: 'upi1',
        requiresPayment: true,
        razorpayOrder: RazorpayOrder(
          keyId: 'k',
          orderId: 'order_1',
          amount: 5500,
        ),
      );
      seedAddresses();
      bloc.add(BookingSubmitRequested());
      await bloc.stream.firstWhere(
        (s) => s.paymentStage == BookingPaymentStage.awaitingCheckout,
      );

      bloc.add(
        const BookingVerifyPaymentRequested(
          parcelId: 'upi1',
          razorpayOrderId: 'order_1',
          razorpayPaymentId: 'pay_1',
          razorpaySignature: 'bad',
        ),
      );
      await bloc.stream.firstWhere(
        (s) => s.paymentStage == BookingPaymentStage.failed,
      );

      expect(bloc.state.paymentMessage, 'Signature verification failed');
      expect(bloc.state.canRetryPayment, isTrue);
    });

    test('a cancelled sheet keeps the order for a retry', () async {
      repo.createResult = const BookingCreationResult(
        parcelId: 'upi1',
        requiresPayment: true,
        razorpayOrder: RazorpayOrder(
          keyId: 'k',
          orderId: 'order_1',
          amount: 5500,
        ),
      );
      seedAddresses();
      bloc.add(BookingSubmitRequested());
      await bloc.stream.firstWhere(
        (s) => s.paymentStage == BookingPaymentStage.awaitingCheckout,
      );

      bloc.add(const BookingPaymentFailed(message: 'Payment cancelled.'));
      await bloc.stream.firstWhere(
        (s) => s.paymentStage == BookingPaymentStage.failed,
      );
      expect(bloc.state.canRetryPayment, isTrue);

      bloc.add(BookingPaymentRetryRequested());
      await bloc.stream.firstWhere(
        (s) => s.paymentStage == BookingPaymentStage.awaitingCheckout,
      );
      expect(bloc.state.pendingOrder!.orderId, 'order_1');
    });

    test('payment required with no order does not read as success', () async {
      repo.createResult = const BookingCreationResult(
        parcelId: 'upi1',
        requiresPayment: true,
      );
      seedAddresses();
      bloc.add(BookingSubmitRequested());

      await bloc.stream.firstWhere(
        (s) => s.paymentStage == BookingPaymentStage.failed,
      );
      expect(bloc.state.paymentStage, isNot(BookingPaymentStage.confirmed));
      expect(bloc.state.paymentMessage, contains('unavailable'));
    });
  });

  group('coupons', () {
    test('applied coupon lowers the payable total and rides on create',
        () async {
      seedAddresses();
      bloc.add(const BookingStepChanged(3));
      await bloc.stream.firstWhere((s) => s.quote != null);

      bloc.add(const BookingCouponApplyRequested('save5'));
      await bloc.stream.firstWhere((s) => s.appliedCoupon != null);

      expect(bloc.state.appliedCoupon!.code, 'SAVE5');
      expect(bloc.state.payableTotal, 50);
    });
  });

  group('fare quoting', () {
    test('refuses to quote without coordinates on both ends', () async {
      bloc.add(
        const BookingPickupUpdated(
          pickup: AddressData(fullAddress: 'Typed but never pinned'),
          sender: PersonData(name: 'Ravi', phone: '9876543210'),
        ),
      );
      bloc.add(BookingCalculateFareRequested());

      await bloc.stream.firstWhere((s) => s.errorMessage != null);
      expect(bloc.state.errorMessage, contains('map'));
      expect(bloc.state.quote, isNull);
    });

    test('a 400 is surfaced as serviceability, not a generic failure',
        () async {
      repo.fareError = const ApiException(
        message: 'We do not deliver to this area yet',
        statusCode: 400,
      );
      seedAddresses();
      bloc.add(BookingCalculateFareRequested());

      await bloc.stream.firstWhere((s) => s.serviceabilityMessage != null);
      expect(
        bloc.state.serviceabilityMessage,
        'We do not deliver to this area yet',
      );
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.quote, isNull);
    });

    test('express selection re-quotes with the surcharged speed', () async {
      seedAddresses();
      bloc.add(const BookingStepChanged(3));
      await bloc.stream.firstWhere((s) => s.quote != null);
      expect(repo.lastFareSpeed, 'normal');

      bloc.add(const BookingDeliverySpeedSelected('express'));
      await bloc.stream.firstWhere((s) => s.deliverySpeed == 'express');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.lastFareSpeed, 'express');
    });
  });

  group('zone check', () {
    test('flags a pin outside a gated delivery zone', () async {
      repo.zone = const ZoneCheckModel(gated: true, covered: false);
      bloc.add(
        const BookingZoneCheckRequested(lat: 1, lng: 2, isPickup: false),
      );

      await bloc.stream.firstWhere((s) => s.serviceabilityMessage != null);
      expect(bloc.state.serviceabilityMessage, contains('deliver'));
    });

    test('stays quiet when zone gating is off', () async {
      repo.zone = const ZoneCheckModel(gated: false, covered: true);
      bloc.add(
        const BookingZoneCheckRequested(lat: 1, lng: 2, isPickup: true),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.serviceabilityMessage, isNull);
    });
  });
}
