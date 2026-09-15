import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/booking_creation_result.dart';
import '../models/city_parcel_booking_request.dart';
import '../models/coupon_models.dart';
import '../models/fare_quote_model.dart';
import '../models/zone_check_model.dart';

abstract class BookingDataSource {
  Future<FareQuoteModel> calculateFare({
    required AddressData pickup,
    required AddressData drop,
    required PackageData package,
    String deliverySpeed,
  });

  Future<BookingCreationResult> createBooking(CityParcelBookingRequest request);

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

class BookingDataSourceImpl implements BookingDataSource {
  final ApiClient apiClient;

  BookingDataSourceImpl({required this.apiClient});

  @override
  Future<FareQuoteModel> calculateFare({
    required AddressData pickup,
    required AddressData drop,
    required PackageData package,
    String deliverySpeed = 'normal',
  }) async {
    final res = await apiClient.post(
      ApiEndpoints.cityParcelFareQuote,
      data: CityParcelBookingRequest.quoteBody(
        pickup: pickup,
        drop: drop,
        package: package,
        deliverySpeed: deliverySpeed,
      ),
    );
    if (res is Map<String, dynamic>) {
      return FareQuoteModel.fromJson(res);
    }
    throw const ApiException(message: 'Invalid fare quote response from server');
  }

  @override
  Future<BookingCreationResult> createBooking(
    CityParcelBookingRequest request,
  ) async {
    final res = await apiClient.post(
      ApiEndpoints.cityParcelCreate,
      data: request.toJson(),
    );
    final result = BookingCreationResult.fromJson(res);
    if (result.parcelId.isEmpty) {
      throw const ApiException(
        message: 'The booking was not created. Please try again.',
      );
    }
    return result;
  }

  @override
  Future<BookingCreationResult> verifyPayment({
    required String parcelId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    // Field names are snake_case because that is what the gateway returns and
    // what the server destructures.
    final res = await apiClient.post(
      ApiEndpoints.cityParcelVerifyPayment(parcelId),
      data: {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
    );
    return BookingCreationResult.fromJson(res);
  }

  @override
  Future<ZoneCheckModel> checkZone({
    required double lat,
    required double lng,
  }) async {
    final res = await apiClient.get(
      ApiEndpoints.cityParcelZoneCheck,
      queryParameters: {'lat': lat, 'lng': lng},
    );
    return ZoneCheckModel.fromJson(res);
  }

  @override
  Future<List<AvailableCoupon>> getAvailableCoupons({double? fare}) async {
    final res = await apiClient.get(
      ApiEndpoints.cityParcelCouponsAvailable,
      queryParameters: {if (fare != null) 'fare': fare},
    );
    return AvailableCoupon.listFrom(res);
  }

  @override
  Future<AppliedCoupon> validateCoupon({
    required AddressData pickup,
    required AddressData drop,
    required PackageData package,
    required String deliverySpeed,
    required String couponCode,
  }) async {
    final res = await apiClient.post(
      ApiEndpoints.cityParcelCouponValidate,
      data: {
        ...CityParcelBookingRequest.quoteBody(
          pickup: pickup,
          drop: drop,
          package: package,
          deliverySpeed: deliverySpeed,
        ),
        'couponCode': couponCode.trim().toUpperCase(),
      },
    );
    return AppliedCoupon.fromJson(res);
  }

  @override
  Future<bool> checkServiceability({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async {
    final res = await apiClient.get(
      ApiEndpoints.cityParcelServiceability,
      queryParameters: {
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropLat': dropLat,
        'dropLng': dropLng,
      },
    );
    final data = (res is Map) ? res : const {};
    // The endpoint answers with a serviceable flag; absent means "no opinion",
    // which must not block a booking.
    return data['serviceable'] != false;
  }
}
