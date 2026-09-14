import '../config/app_environment.dart';

/// Single source of truth for app constants.
/// Environment-specific values (Base URL, Socket URL, Firebase keys) are dynamically
/// resolved via [AppConfig.instance] based on active flavor (Dev, Staging, Prod).
class AppConstants {
  AppConstants._();

  static String get title => AppConfig.instance.appTitle;

  /// Backend REST API base URL (all endpoints are mounted under `/api/v1` or `/api`).
  static String get baseUrl => AppConfig.instance.baseUrl;

  /// Socket.IO server base.
  static String get socketUrl => AppConfig.instance.socketUrl;

  static String get firebaseApiKey => AppConfig.instance.firebaseApiKey;

  static String get firebaseAppId => AppConfig.instance.firebaseAppId;

  static String get firebaseMessagingSenderId =>
      AppConfig.instance.firebaseMessagingSenderId;

  static String get firebaseProjectId => AppConfig.instance.firebaseProjectId;

  /// Google Maps API key (Maps SDK for Android/iOS + Geocoding API enabled).
  static const String mapKey = 'AIzaSyDD05BmwVMKWlUlxKZNDr78JAqiIEaabXo';

  /// Razorpay / Payment publishable key.
  static const String stripPublishKey = 'rzp_test_SatrrxFwKXJX8e';

  static const String packageName = 'com.sungguard.user';

  /// Release keystore signing key alias/password.
  static const String signKey = '';

  // --- App behaviour constants (unrelated to environment/build config) ---
  static const int otpLength = 4;
  static const int phoneLength = 10;
  static const double defaultZoomLevel = 16;
  static const Duration otpResendCooldown = Duration(seconds: 30);
}
