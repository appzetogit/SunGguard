import '../config/app_environment.dart';

abstract final class ApiEndpoints {
  // Base URLs — resolved from the active flavor (AppConfig), with the live
  // Render backend as the fallback before AppConfig is initialised.
  static const String _fallbackBaseUrl =
      'https://sungguard-v8f2.onrender.com/api';
  static const String _fallbackSocketUrl = 'https://sungguard-v8f2.onrender.com';

  static String get defaultBaseUrl {
    try {
      final url = AppConfig.instance.baseUrl;
      return url.isNotEmpty ? url : _fallbackBaseUrl;
    } catch (_) {
      return _fallbackBaseUrl;
    }
  }

  static String get defaultSocketUrl {
    try {
      final url = AppConfig.instance.socketUrl;
      return url.isNotEmpty ? url : _fallbackSocketUrl;
    } catch (_) {
      return _fallbackSocketUrl;
    }
  }

  // Customer Auth
  static const String customerSendLoginOtp = '/customer/send-login-otp';
  static const String customerSendSignupOtp = '/customer/send-signup-otp';
  static const String customerVerifyOtp = '/customer/verify-otp';
  static const String customerProfile = '/customer/profile';
  static const String customerTransactions = '/customer/transactions';
  static const String customerNotifications = '/notifications';

  // City Parcel (Local Delivery)
  static const String cityParcelBookingConfig = '/city-parcel/booking-config';
  static const String cityParcelServiceability = '/city-parcel/serviceability';
  static const String cityParcelCalculateFare = '/city-parcel/calculate-fare';
  static const String cityParcelCreate = '/city-parcel/create';
  static const String cityParcelCouponsAvailable = '/city-parcel/coupons/available';
  static const String cityParcelCouponValidate = '/city-parcel/coupon/validate';
  static String cityParcelVerifyPayment(String id) =>
      '/city-parcel/$id/verify-payment';
  static const String cityParcelHistory = '/city-parcel/history';
  static const String cityParcelActive = '/city-parcel/history';
  static String cityParcelTrack(String id) => '/city-parcel/track/$id';
  static String cityParcelMyCode(String id) => '/city-parcel/$id/my-code';
  static String cityParcelFailureResponse(String id) =>
      '/city-parcel/$id/failure-response';
  static String cityParcelCancel(String id) => '/city-parcel/$id/cancel';

  // Outstation Parcel
  static const String outstationParcelBookingConfig = '/parcel/booking-config';
  static const String outstationParcelCalculateFare = '/parcel/calculate-fare';
  static const String outstationParcelCreate = '/parcel/create';
  static const String outstationParcelCouponsAvailable = '/parcel/coupons/available';
  static const String outstationParcelCouponValidate = '/parcel/coupon/validate';
  static const String outstationParcelNearestWarehouse = '/warehouse/nearest';
  static const String outstationParcelVerifyPayment = '/parcel/verify-payment';
  static const String outstationParcelHistory = '/parcel/history';
  static String outstationParcelTrack(String id) => '/parcel/track/$id';
  static String outstationParcelCancel(String id) => '/parcel/cancel/$id';
  static String outstationParcelLateRefund(String id) =>
      '/parcel/$id/late-refund-request';
  static const String outstationParcelReviews = '/parcel/reviews';

  // Outstation Parcel Reviews (customer's own rating)
  static const String outstationParcelSubmitReview = '/parcel/review';
  static String outstationParcelMyReview(String parcelId) =>
      '/parcel/review/$parcelId';

  // Warehouses
  static const String warehousesActive = '/warehouse/active';

  // Support Tickets
  static const String createTicket = '/tickets/create';
  static const String myTickets = '/tickets/my-tickets';
  static String replyTicket(String id) => '/tickets/reply/$id';

  // Push notifications (device token registry)
  static const String pushRegister = '/push/register';
  static const String pushRemove = '/push/remove';
  static const String pushPreferences = '/push/preferences';

  // Notifications
  static const String notificationsMarkRead = '/notifications/read';

  // Media
  static const String mediaUpload = '/media/upload';

  // Platform settings (support contacts, currency, payment switches)
  static const String settings = '/settings';

  // City Parcel serviceability pre-checks
  static const String cityParcelZoneCheck = '/city-parcel/zone-check';

  // Legacy aliases for backwards compatibility
  static const String customerSendLoginOtpLegacy = customerSendLoginOtp;
  static const String customerVerifyLoginOtpLegacy = customerVerifyOtp;
  static const String customerSendSignupOtpLegacy = customerSendSignupOtp;
  static const String customerVerifySignupOtpLegacy = customerVerifyOtp;
  static const String customerUpdateProfile = customerProfile;
  static const String cityParcelFareQuote = cityParcelCalculateFare;
  static String cityParcelDetail(String id) => cityParcelTrack(id);
  static String cityParcelRequestCode(String id) => cityParcelMyCode(id);
  static String cityParcelDecision(String id) => cityParcelFailureResponse(id);
  static const String outstationParcelRates = outstationParcelCalculateFare;
  static const String addresses = customerProfile;
  static const String wallet = customerTransactions;
}
