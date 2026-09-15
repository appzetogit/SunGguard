import '../datasources/booking_datasource.dart';
import '../models/booking_creation_result.dart';
import '../models/city_parcel_booking_request.dart';
import '../models/coupon_models.dart';
import '../models/zone_check_model.dart';
import '../../domain/entities/fare_quote_entity.dart';
import '../../domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingDataSource dataSource;

  BookingRepositoryImpl({required this.dataSource});

  @override
  Future<FareQuoteEntity> calculateFare({
    required AddressData pickup,
    required AddressData drop,
    required PackageData package,
    String deliverySpeed = 'normal',
  }) {
    return dataSource.calculateFare(
      pickup: pickup,
      drop: drop,
      package: package,
      deliverySpeed: deliverySpeed,
    );
  }

  @override
  Future<BookingCreationResult> createBooking(
    CityParcelBookingRequest request,
  ) {
    return dataSource.createBooking(request);
  }

  @override
  Future<BookingCreationResult> verifyPayment({
    required String parcelId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) {
    return dataSource.verifyPayment(
      parcelId: parcelId,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    );
  }

  @override
  Future<ZoneCheckModel> checkZone({
    required double lat,
    required double lng,
  }) {
    return dataSource.checkZone(lat: lat, lng: lng);
  }

  @override
  Future<List<AvailableCoupon>> getAvailableCoupons({double? fare}) =>
      dataSource.getAvailableCoupons(fare: fare);

  @override
  Future<AppliedCoupon> validateCoupon({
    required AddressData pickup,
    required AddressData drop,
    required PackageData package,
    required String deliverySpeed,
    required String couponCode,
  }) =>
      dataSource.validateCoupon(
        pickup: pickup,
        drop: drop,
        package: package,
        deliverySpeed: deliverySpeed,
        couponCode: couponCode,
      );

  @override
  Future<bool> checkServiceability({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) {
    return dataSource.checkServiceability(
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropLat: dropLat,
      dropLng: dropLng,
    );
  }
}
