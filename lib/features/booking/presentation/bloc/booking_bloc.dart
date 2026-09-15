import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../data/models/city_parcel_booking_request.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository bookingRepository;

  BookingBloc({required this.bookingRepository}) : super(const BookingState()) {
    on<BookingResetRequested>(_onResetRequested);
    on<BookingStepChanged>(_onStepChanged);
    on<BookingPickupUpdated>(_onPickupUpdated);
    on<BookingDropUpdated>(_onDropUpdated);
    on<BookingPackageUpdated>(_onPackageUpdated);
    on<BookingPaymentMethodSelected>(_onPaymentMethodSelected);
    on<BookingDeliverySpeedSelected>(_onDeliverySpeedSelected);
    on<BookingZoneCheckRequested>(_onZoneCheckRequested);
    on<BookingCalculateFareRequested>(_onCalculateFareRequested);
    on<BookingSubmitRequested>(_onSubmitRequested);
    on<BookingVerifyPaymentRequested>(_onVerifyPaymentRequested);
    on<BookingPaymentFailed>(_onPaymentFailed);
    on<BookingPaymentRetryRequested>(_onPaymentRetryRequested);
    on<BookingCouponsLoadRequested>(_onCouponsLoadRequested);
    on<BookingCouponApplyRequested>(_onCouponApplyRequested);
    on<BookingCouponRemoved>(_onCouponRemoved);
  }

  Future<void> _onCouponsLoadRequested(
    BookingCouponsLoadRequested event,
    Emitter<BookingState> emit,
  ) async {
    final fare = state.quote?.total;
    if (fare == null || fare <= 0) return;
    try {
      final coupons = await bookingRepository.getAvailableCoupons(fare: fare);
      emit(state.copyWith(availableCoupons: coupons));
    } catch (_) {
      emit(state.copyWith(availableCoupons: const []));
    }
  }

  Future<void> _onCouponApplyRequested(
    BookingCouponApplyRequested event,
    Emitter<BookingState> emit,
  ) async {
    final code = event.code.trim().toUpperCase();
    if (code.isEmpty || state.quote == null) return;
    emit(state.copyWith(isApplyingCoupon: true, couponError: null));
    try {
      final applied = await bookingRepository.validateCoupon(
        pickup: state.pickup,
        drop: state.drop,
        package: state.package,
        deliverySpeed: state.deliverySpeed,
        couponCode: code,
      );
      emit(state.copyWith(isApplyingCoupon: false, appliedCoupon: applied));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isApplyingCoupon: false,
        clearCoupon: true,
        couponError: e.message.isNotEmpty ? e.message : "Couldn't apply this coupon",
      ));
    } catch (_) {
      emit(state.copyWith(
        isApplyingCoupon: false,
        clearCoupon: true,
        couponError: "Couldn't apply this coupon",
      ));
    }
  }

  void _onCouponRemoved(BookingCouponRemoved event, Emitter<BookingState> emit) {
    emit(state.copyWith(clearCoupon: true, couponError: null));
  }

  void _onResetRequested(
    BookingResetRequested event,
    Emitter<BookingState> emit,
  ) {
    emit(const BookingState());
  }

  void _onStepChanged(BookingStepChanged event, Emitter<BookingState> emit) {
    emit(state.copyWith(currentStep: event.step));
    if (event.step == 3) {
      add(BookingCalculateFareRequested());
    }
  }

  void _onPickupUpdated(
    BookingPickupUpdated event,
    Emitter<BookingState> emit,
  ) {
    emit(state.copyWith(pickup: event.pickup, sender: event.sender));
  }

  void _onDropUpdated(BookingDropUpdated event, Emitter<BookingState> emit) {
    emit(state.copyWith(drop: event.drop, receiver: event.receiver));
  }

  void _onPackageUpdated(
    BookingPackageUpdated event,
    Emitter<BookingState> emit,
  ) {
    emit(state.copyWith(package: event.package));
  }

  void _onPaymentMethodSelected(
    BookingPaymentMethodSelected event,
    Emitter<BookingState> emit,
  ) {
    emit(state.copyWith(paymentMethod: event.paymentMethod));
  }

  void _onDeliverySpeedSelected(
    BookingDeliverySpeedSelected event,
    Emitter<BookingState> emit,
  ) {
    emit(state.copyWith(deliverySpeed: event.deliverySpeed));
    // Express carries a surcharge, so the quote is no longer valid.
    if (state.currentStep == 3) add(BookingCalculateFareRequested());
  }

  Future<void> _onZoneCheckRequested(
    BookingZoneCheckRequested event,
    Emitter<BookingState> emit,
  ) async {
    try {
      final zone = await bookingRepository.checkZone(
        lat: event.lat,
        lng: event.lng,
      );
      if (zone.isOutOfServiceArea) {
        emit(
          state.copyWith(
            serviceabilityMessage: event.isPickup
                ? "We don't pick up from this area yet."
                : "We don't deliver to this area yet.",
          ),
        );
      } else {
        emit(state.copyWith(serviceabilityMessage: null));
      }
    } catch (_) {
      // A failed check must never block the booking — the fare quote and the
      // create call both re-validate serviceability server-side anyway.
    }
  }

  Future<void> _onCalculateFareRequested(
    BookingCalculateFareRequested event,
    Emitter<BookingState> emit,
  ) async {
    // Coordinates are mandatory server-side; asking for a quote without them
    // returns a 400 the customer cannot act on.
    if (!state.pickup.isComplete || !state.drop.isComplete) {
      emit(
        state.copyWith(
          isQuoting: false,
          clearQuote: true,
          errorMessage: 'Pick both addresses on the map to see the price',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isQuoting: true,
        errorMessage: null,
        serviceabilityMessage: null,
      ),
    );
    try {
      final quote = await bookingRepository.calculateFare(
        pickup: state.pickup,
        drop: state.drop,
        package: state.package,
        deliverySpeed: state.deliverySpeed,
      );
      // A new quote invalidates a coupon priced against the old fare.
      emit(state.copyWith(isQuoting: false, quote: quote, clearCoupon: true));
      add(BookingCouponsLoadRequested());
    } on ApiException catch (e) {
      // A 400 from calculate-fare is the serviceability verdict: out of zone,
      // or beyond the maximum trip distance. It deserves its own surface
      // rather than a generic failure toast.
      final isServiceability = e.statusCode == 400;
      emit(
        state.copyWith(
          isQuoting: false,
          clearQuote: true,
          serviceabilityMessage: isServiceability ? e.message : null,
          errorMessage: isServiceability ? null : e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isQuoting: false,
          clearQuote: true,
          errorMessage: "Couldn't price this delivery",
        ),
      );
    }
  }

  Future<void> _onSubmitRequested(
    BookingSubmitRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(
      state.copyWith(
        isPlacing: true,
        errorMessage: null,
        paymentMessage: null,
        paymentStage: BookingPaymentStage.none,
      ),
    );
    try {
      final request = CityParcelBookingRequest(
        pickupAddress: state.pickup,
        dropAddress: state.drop,
        sender: state.sender,
        receiver: state.receiver,
        package: state.package,
        paymentMethod: state.paymentMethod,
        deliverySpeed: state.deliverySpeed,
        couponCode: state.appliedCoupon?.code,
      );

      final result = await bookingRepository.createBooking(request);

      if (result.isBrokenPaymentSetup) {
        // Server wants payment but sent no usable order. Surfacing this as an
        // error is the honest outcome — silently "succeeding" would strand the
        // booking with no rider and no way to pay.
        emit(
          state.copyWith(
            isPlacing: false,
            createdParcelId: result.parcelId,
            paymentStage: BookingPaymentStage.failed,
            paymentMessage:
                'Online payment is unavailable right now. Try cash on pickup.',
          ),
        );
        return;
      }

      if (result.isPayable) {
        // Parcel exists but stays unbroadcast until the signature verifies.
        emit(
          state.copyWith(
            isPlacing: false,
            createdParcelId: result.parcelId,
            pendingOrder: result.razorpayOrder,
            paymentStage: BookingPaymentStage.awaitingCheckout,
          ),
        );
        return;
      }

      // COD: the backend has already started looking for a rider.
      emit(
        state.copyWith(
          isPlacing: false,
          createdParcelId: result.parcelId,
          paymentStage: BookingPaymentStage.confirmed,
        ),
      );
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString();
      emit(
        state.copyWith(
          isPlacing: false,
          errorMessage:
              msg.isNotEmpty ? msg : "Couldn't place the parcel booking",
        ),
      );
    }
  }

  Future<void> _onVerifyPaymentRequested(
    BookingVerifyPaymentRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(paymentStage: BookingPaymentStage.verifying));
    try {
      await bookingRepository.verifyPayment(
        parcelId: event.parcelId,
        razorpayOrderId: event.razorpayOrderId,
        razorpayPaymentId: event.razorpayPaymentId,
        razorpaySignature: event.razorpaySignature,
      );
      emit(
        state.copyWith(
          paymentStage: BookingPaymentStage.confirmed,
          createdParcelId: event.parcelId,
        ),
      );
    } on ApiException catch (e) {
      // The money may well have left the customer's account — the server
      // deliberately leaves the booking PENDING rather than FAILED so a
      // genuine payment can still be applied. Say so instead of implying the
      // booking is dead.
      emit(
        state.copyWith(
          paymentStage: BookingPaymentStage.failed,
          paymentMessage: e.message.isNotEmpty
              ? e.message
              : "We couldn't confirm the payment. If you were charged, it will "
                  'be applied shortly.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          paymentStage: BookingPaymentStage.failed,
          paymentMessage:
              "We couldn't confirm the payment. If you were charged, it will "
              'be applied shortly.',
        ),
      );
    }
  }

  void _onPaymentFailed(
    BookingPaymentFailed event,
    Emitter<BookingState> emit,
  ) {
    emit(
      state.copyWith(
        paymentStage: BookingPaymentStage.failed,
        paymentMessage: event.message,
      ),
    );
  }

  void _onPaymentRetryRequested(
    BookingPaymentRetryRequested event,
    Emitter<BookingState> emit,
  ) {
    // Same as the web app: create again. The backend resumes the same unpaid
    // booking and opens a fresh gateway order (an abandoned order cannot be
    // reused, and unpaid rows are swept after two hours).
    add(BookingSubmitRequested());
  }
}
