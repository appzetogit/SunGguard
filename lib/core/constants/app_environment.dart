import 'app_constants.dart';

abstract final class AppEnvironment {
  // Backend Endpoints
  static String get baseUrl => AppConstants.baseUrl;
  static String get socketUrl => AppConstants.socketUrl;

  // Razorpay Gateway
  static const String razorpayKeyId = AppConstants.stripPublishKey;

  // Google Maps API
  static const String googleMapsApiKey = AppConstants.mapKey;

  // Firebase Credentials
  static String get firebaseApiKey => AppConstants.firebaseApiKey;
  static const String firebaseDatabaseUrl =
      'https://courier-app-21b4f-default-rtdb.firebaseio.com';
  static String get firebaseProjectId => AppConstants.firebaseProjectId;
  static const String firebaseStorageBucket =
      'courier-app-21b4f.firebasestorage.app';
  static String get firebaseMessagingSenderId =>
      AppConstants.firebaseMessagingSenderId;
  static String get firebaseAppId => AppConstants.firebaseAppId;
}
