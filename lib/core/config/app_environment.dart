import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

enum AppEnvironment { dev, staging, prod }

/// Global configuration class for environment-specific variables.
/// Contains inline English documentation for Admin / Developers to easily 
/// update backend endpoints and Firebase credentials per environment.
class AppConfig {
  final AppEnvironment environment;
  final String appTitle;
  final String baseUrl;
  final String socketUrl;
  final String firebaseApiKey;
  final String firebaseAppId;
  final String firebaseMessagingSenderId;
  final String firebaseProjectId;

  static late AppConfig instance;

  AppConfig._({
    required this.environment,
    required this.appTitle,
    required this.baseUrl,
    required this.socketUrl,
    required this.firebaseApiKey,
    required this.firebaseAppId,
    required this.firebaseMessagingSenderId,
    required this.firebaseProjectId,
  });

  /// Initializes environment configuration for the specified [AppEnvironment].
  static void initialize(AppEnvironment env) {
    switch (env) {
      case AppEnvironment.dev:
        instance = AppConfig._(
          environment: AppEnvironment.dev,
          appTitle: 'SunGguard Dev',

          // ===================================================================
          // 📝 NOTE FOR ADMIN / DEVELOPER (DEV ENVIRONMENT):
          // Change the Base URL, Socket URL, and Firebase credentials for 
          // the DEVELOPMENT environment below when a dedicated dev server is ready.
          // ===================================================================
          baseUrl: 'https://sungguard-v8f2.onrender.com/api',
          socketUrl: 'https://sungguard-v8f2.onrender.com',
          firebaseApiKey: (kIsWeb || Platform.isAndroid)
              ? 'AIzaSyA5N3H1123TyU47oljr3l5J_QUPCLLvwEQ'
              : '',
          firebaseAppId: (kIsWeb || Platform.isAndroid)
              ? '1:326668543295:android:eb72f02f04b0fc92d01f8a'
              : '',
          firebaseMessagingSenderId: (kIsWeb || Platform.isAndroid)
              ? '326668543295'
              : '',
          firebaseProjectId: (kIsWeb || Platform.isAndroid)
              ? 'courier-app-21b4f'
              : '',
        );
        break;

      case AppEnvironment.staging:
        instance = AppConfig._(
          environment: AppEnvironment.staging,
          appTitle: 'SunGguard Staging',

          // ===================================================================
          // 📝 NOTE FOR ADMIN / DEVELOPER (STAGING ENVIRONMENT):
          // Change the Base URL, Socket URL, and Firebase credentials for 
          // the STAGING / QA TESTING environment below when ready.
          // ===================================================================
          baseUrl: 'https://sungguard-v8f2.onrender.com/api',
          socketUrl: 'https://sungguard-v8f2.onrender.com',
          firebaseApiKey: (kIsWeb || Platform.isAndroid)
              ? 'AIzaSyA5N3H1123TyU47oljr3l5J_QUPCLLvwEQ'
              : '',
          firebaseAppId: (kIsWeb || Platform.isAndroid)
              ? '1:326668543295:android:eb72f02f04b0fc92d01f8a'
              : '',
          firebaseMessagingSenderId: (kIsWeb || Platform.isAndroid)
              ? '326668543295'
              : '',
          firebaseProjectId: (kIsWeb || Platform.isAndroid)
              ? 'courier-app-21b4f'
              : '',
        );
        break;

      case AppEnvironment.prod:
        instance = AppConfig._(
          environment: AppEnvironment.prod,
          appTitle: 'SunGguard',

          // ===================================================================
          // 📝 NOTE FOR ADMIN / DEVELOPER (PRODUCTION ENVIRONMENT):
          // Change the Base URL, Socket URL, and Firebase credentials for 
          // the LIVE PRODUCTION environment below when deployed to production.
          // ===================================================================
          baseUrl: 'https://sungguard-v8f2.onrender.com/api',
          socketUrl: 'https://sungguard-v8f2.onrender.com',
          firebaseApiKey: (kIsWeb || Platform.isAndroid)
              ? 'AIzaSyA5N3H1123TyU47oljr3l5J_QUPCLLvwEQ'
              : '',
          firebaseAppId: (kIsWeb || Platform.isAndroid)
              ? '1:326668543295:android:eb72f02f04b0fc92d01f8a'
              : '',
          firebaseMessagingSenderId: (kIsWeb || Platform.isAndroid)
              ? '326668543295'
              : '',
          firebaseProjectId: (kIsWeb || Platform.isAndroid)
              ? 'courier-app-21b4f'
              : '',
        );
        break;
    }
  }
}
