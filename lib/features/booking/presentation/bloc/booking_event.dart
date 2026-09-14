import 'package:equatable/equatable.dart';
import '../../data/models/city_parcel_booking_request.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class BookingResetRequested extends BookingEvent {}

class BookingStepChanged extends BookingEvent {
  final int step;

  const BookingStepChanged(this.step);

  @override
  List<Object?> get props => [step];
}

class BookingPickupUpdated extends BookingEvent {
  final AddressData pickup;
  final PersonData sender;

  const BookingPickupUpdated({required this.pickup, required this.sender});

  @override
  List<Object?> get props => [pickup, sender];
}

class BookingDropUpdated extends BookingEvent {
  final AddressData drop;
  final PersonData receiver;

  const BookingDropUpdated({required this.drop, required this.receiver});

  @override
  List<Object?> get props => [drop, receiver];
}

class BookingPackageUpdated extends BookingEvent {
  final PackageData package;

  const BookingPackageUpdated(this.package);

  @override
  List<Object?> get props => [package];
}

class BookingPaymentMethodSelected extends BookingEvent {
  final String paymentMethod;

  const BookingPaymentMethodSelected(this.paymentMethod);

  @override
  List<Object?> get props => [paymentMethod];
}

class BookingDeliverySpeedSelected extends BookingEvent {
  final String deliverySpeed; // 'normal' | 'express'

  const BookingDeliverySpeedSelected(this.deliverySpeed);

  @override
  List<Object?> get props => [deliverySpeed];
}

/// Asks whether a freshly dropped pin is inside a delivery zone.
///
/// The backend exposes this so the customer is told "we don't cover this"
/// while still looking at the map, rather than at the payment step.
class BookingZoneCheckRequested extends BookingEvent {
  final double lat;
  final double lng;
  final bool isPickup;

  const BookingZoneCheckRequested({
    required this.lat,
    required this.lng,
    required this.isPickup,
  });

  @override
  List<Object?> get props => [lat, lng, isPickup];
}

class BookingCalculateFareRequested extends BookingEvent {}

class BookingSubmitRequested extends BookingEvent {}

/// Posts the Razorpay signature triple so the server releases the parcel.
class BookingVerifyPaymentRequested extends BookingEvent {
  final String parcelId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  const BookingVerifyPaymentRequested({
    required this.parcelId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  @override
  List<Object?> get props =>
      [parcelId, razorpayOrderId, razorpayPaymentId, razorpaySignature];
}

/// Checkout was dismissed or the gateway reported a failure. The booking is
/// left intact so it can be retried.
class BookingPaymentFailed extends BookingEvent {
  final String? message;

  const BookingPaymentFailed({this.message});

  @override
  List<Object?> get props => [message];
}

/// Re-opens the gateway for a booking created but never paid for.
class BookingPaymentRetryRequested extends BookingEvent {}

/// Loads `GET /city-parcel/coupons/available?fare=` once a quote exists.
class BookingCouponsLoadRequested extends BookingEvent {}

/// `POST /city-parcel/coupon/validate` with the current trip + [code].
class BookingCouponApplyRequested extends BookingEvent {
  final String code;

  const BookingCouponApplyRequested(this.code);

  @override
  List<Object?> get props => [code];
}

class BookingCouponRemoved extends BookingEvent {}
