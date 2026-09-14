import '../../data/models/booking_creation_result.dart';
import '../../data/models/city_parcel_booking_request.dart';
import '../../data/models/coupon_models.dart';
import '../../data/models/zone_check_model.dart';
import '../entities/fare_quote_entity.dart';

abstract class BookingRepository {
  Future<FareQuoteEntity> calculateFare({
    required AddressData pickup,
    required AddressData drop,
    required PackageData package,
    String deliverySpeed,
  });

  Future<BookingCreationResult> createBooking(CityParcelBookingRequest request);

  /// Confirms an online payment so the backend releases the parcel to riders.
  Future<BookingCreationResult> verifyPayment({
    required String parcelId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  });

  Future<ZoneCheckModel> checkZone({required double lat, required double lng});

  Future<List<AvailableCoupon>> getAvailableCoupons({double? fare});

  Future<AppliedCoupon> validateCoupon({
    required AddressData pickup,
    required AddressData drop,
    required PackageData package,
    required String deliverySpeed,
    required String couponCode,
  });

  Future<bool> checkServiceability({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  });
}
