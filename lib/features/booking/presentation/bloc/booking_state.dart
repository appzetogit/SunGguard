import 'package:equatable/equatable.dart';

import '../../../../core/services/razorpay_checkout_service.dart';
import '../../data/models/city_parcel_booking_request.dart';
import '../../data/models/coupon_models.dart';
import '../../domain/entities/fare_quote_entity.dart';

/// Where a booking is in the create → pay → verify sequence.
enum BookingPaymentStage {
  /// Nothing submitted yet, or COD (which needs no gateway step).
  none,

  /// Server returned `requiresPayment: true` and an open Razorpay order.
  /// The parcel exists but is unbroadcast until the signature is verified.
  awaitingCheckout,

  /// Checkout succeeded; the signature is being posted to the server.
  verifying,

  /// Verified. The backend has released the parcel to riders.
  confirmed,

  /// Checkout was dismissed or the signature was rejected. The booking is
  /// still alive and can be retried.
  failed,
}

class BookingState extends Equatable {
  final int currentStep; // 0: From, 1: To, 2: What, 3: Pay
  final AddressData pickup;
  final AddressData drop;
  final PersonData sender;
  final PersonData receiver;
  final PackageData package;
  final String paymentMethod;
  final String deliverySpeed;
  final FareQuoteEntity? quote;
  final bool isQuoting;
  final bool isPlacing;
  final String? createdParcelId;
  final String? errorMessage;

  /// Set when the fare quote is refused because the trip is outside a
  /// delivery zone or beyond the maximum distance.
  final String? serviceabilityMessage;

  final BookingPaymentStage paymentStage;
  final RazorpayOrder? pendingOrder;
  final String? paymentMessage;

  /// Coupons (same flow as the web booking screen).
  final List<AvailableCoupon> availableCoupons;
  final AppliedCoupon? appliedCoupon;
  final bool isApplyingCoupon;
  final String? couponError;

  const BookingState({
    this.currentStep = 0,
    this.pickup = const AddressData(fullAddress: '', line: '', landmark: ''),
    this.drop = const AddressData(fullAddress: '', line: '', landmark: ''),
    this.sender = const PersonData(name: '', phone: ''),
    this.receiver = const PersonData(name: '', phone: ''),
    this.package = const PackageData(
      packageType: 'Documents',
      weightKg: 0.0,
      description: '',
    ),
    this.paymentMethod = 'UPI',
    this.deliverySpeed = 'normal',
    this.quote,
    this.isQuoting = false,
    this.isPlacing = false,
    this.createdParcelId,
    this.errorMessage,
    this.serviceabilityMessage,
    this.paymentStage = BookingPaymentStage.none,
    this.pendingOrder,
    this.paymentMessage,
    this.availableCoupons = const [],
    this.appliedCoupon,
    this.isApplyingCoupon = false,
    this.couponError,
  });

  bool get isCod => paymentMethod.trim().toUpperCase() == 'COD';

  /// What the customer actually pays: the coupon's `payableFare` when one is
  /// applied, otherwise the quoted `fare`.
  double get payableTotal => appliedCoupon?.payableFare ?? quote?.total ?? 0.0;

  /// Both endpoints must be map-resolved before anything can be priced or
  /// booked — the server requires coordinates on each address.
  bool get canProceedStep0 =>
      pickup.isComplete && sender.name.isNotEmpty && sender.phone.isNotEmpty;

  bool get canProceedStep1 =>
      drop.isComplete && receiver.name.isNotEmpty && receiver.phone.isNotEmpty;

  bool get canProceedStep2 =>
      package.packageType.isNotEmpty && package.weightKg >= 0.1;

  /// The gateway sheet is open or the signature is in flight; the confirm
  /// button must stay locked so a second order cannot be opened.
  bool get isPaymentInFlight =>
      paymentStage == BookingPaymentStage.awaitingCheckout ||
      paymentStage == BookingPaymentStage.verifying;

  /// A created-but-unpaid booking the customer can retry.
  bool get canRetryPayment =>
      paymentStage == BookingPaymentStage.failed && createdParcelId != null;

  BookingState copyWith({
    int? currentStep,
    AddressData? pickup,
    AddressData? drop,
    PersonData? sender,
    PersonData? receiver,
    PackageData? package,
    String? paymentMethod,
    String? deliverySpeed,
    FareQuoteEntity? quote,
    bool? isQuoting,
    bool? isPlacing,
    String? createdParcelId,
    String? errorMessage,
    String? serviceabilityMessage,
    BookingPaymentStage? paymentStage,
    RazorpayOrder? pendingOrder,
    String? paymentMessage,
    bool clearQuote = false,
    List<AvailableCoupon>? availableCoupons,
    AppliedCoupon? appliedCoupon,
    bool clearCoupon = false,
    bool? isApplyingCoupon,
    String? couponError,
  }) {
    return BookingState(
      currentStep: currentStep ?? this.currentStep,
      pickup: pickup ?? this.pickup,
      drop: drop ?? this.drop,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      package: package ?? this.package,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliverySpeed: deliverySpeed ?? this.deliverySpeed,
      quote: clearQuote ? null : (quote ?? this.quote),
      isQuoting: isQuoting ?? this.isQuoting,
      isPlacing: isPlacing ?? this.isPlacing,
      createdParcelId: createdParcelId ?? this.createdParcelId,
      // Transient: cleared unless explicitly re-set, so a stale error is not
      // re-shown on the next rebuild.
      errorMessage: errorMessage,
      serviceabilityMessage: serviceabilityMessage,
      paymentStage: paymentStage ?? this.paymentStage,
      pendingOrder: pendingOrder ?? this.pendingOrder,
      paymentMessage: paymentMessage,
      availableCoupons: availableCoupons ?? this.availableCoupons,
      appliedCoupon: (clearCoupon || clearQuote) ? null : (appliedCoupon ?? this.appliedCoupon),
      isApplyingCoupon: isApplyingCoupon ?? this.isApplyingCoupon,
      couponError: couponError,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        pickup,
        drop,
        sender,
        receiver,
        package,
        paymentMethod,
        deliverySpeed,
        quote,
        isQuoting,
        isPlacing,
        createdParcelId,
        errorMessage,
        serviceabilityMessage,
        paymentStage,
        pendingOrder,
        paymentMessage,
        availableCoupons,
        appliedCoupon,
        isApplyingCoupon,
        couponError,
      ];
}
