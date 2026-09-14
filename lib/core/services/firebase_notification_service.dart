import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: AppConstants.firebaseApiKey,
      appId: AppConstants.firebaseAppId,
      messagingSenderId: AppConstants.firebaseMessagingSenderId,
      projectId: AppConstants.firebaseProjectId,
    ),
  );
  debugPrint(
    "🔔 [FCM Background Message]: ${message.messageId} - ${message.notification?.title}",
  );
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();

  factory FirebaseNotificationService() => _instance;

  FirebaseNotificationService._internal();

  String? fcmToken;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sungguard_high_importance_channel',
    'High Importance Notifications',
    description:
        'This channel is used for important parcel & delivery notifications.',
    importance: Importance.max,
  );

  /// True when this platform actually has Firebase credentials configured.
  ///
  /// [AppConfig] only fills these for Android and web, so on iOS every value
  /// is an empty string and `Firebase.initializeApp` throws — a failure that
  /// was previously swallowed by the outer catch, leaving no clue why pushes
  /// never worked. Checking first turns it into one explicit log line.
  bool get isConfigured =>
      AppConstants.firebaseApiKey.isNotEmpty &&
      AppConstants.firebaseAppId.isNotEmpty &&
      AppConstants.firebaseProjectId.isNotEmpty;

  Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint(
        '⚠️ [Firebase] No credentials for this platform — push notifications '
        'are disabled. Add the platform to AppConfig to enable them.',
      );
      return;
    }
    try {
      // 1. Initialize Firebase App with options from AppConstants
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: AppConstants.firebaseApiKey,
          appId: AppConstants.firebaseAppId,
          messagingSenderId: AppConstants.firebaseMessagingSenderId,
          projectId: AppConstants.firebaseProjectId,
        ),
      );

      // 2. Register background messaging handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 3. Initialize Local Notifications Plugin
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('🚀 [Local Notification Tap]: ${details.payload}');
        },
      );

      // Create Android Notification Channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      // 4. Request user notification permission
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      debugPrint('🔔 [FCM Permission Status]: ${settings.authorizationStatus}');

      // Set FCM foreground presentation options
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      // 5. Retrieve FCM Token
      fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('🔑 [FCM Token]: $fcmToken');

      // Listen to token refreshes. A refreshed token invalidates the one the
      // server holds, so it has to be re-registered or pushes stop arriving.
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        fcmToken = newToken;
        debugPrint('🔑 [FCM Token Refreshed]');
        registerTokenWithBackend();
      });

      // 6. Foreground Notification Listener (Triggers Local Notification Banner)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '🔔 [FCM Foreground Notification Received]: ${message.notification?.title} - ${message.notification?.body}',
        );

        RemoteNotification? notification = message.notification;

        if (notification != null) {
          showLocalNotification(
            id: notification.hashCode,
            title: notification.title ?? 'SunGguard Update',
            body: notification.body ?? '',
            payload: message.data.toString(),
          );
        }
      });

      // 7. Notification Click Handler (App Opened from Background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🚀 [FCM Notification Clicked]: ${message.data}');
      });

      // 8. Initial Notification (App Launched from Terminated state)
      RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '🚀 [FCM App Launched from Notification]: ${initialMessage.data}',
        );
      }
    } catch (e) {
      debugPrint('❌ [FirebaseNotificationService Error]: $e');
    }
  }

  /// Sends this device's FCM token to the backend so it can be pushed to.
  ///
  /// `POST /api/push/register` requires an authenticated customer, so this is
  /// called after sign-in (and on every token refresh) rather than at boot.
  /// Until this existed the token was only ever printed to the debug console,
  /// which meant no push notification could reach any user.
  Future<void> registerTokenWithBackend() async {
    if (!isConfigured) return;
    final token = fcmToken ?? await _readToken();
    if (token == null || token.isEmpty) return;

    try {
      final client = ApiClient.createDefault();
      final stored = await client.secureStorage.getCustomerToken();
      if (stored == null || stored.isEmpty) return; // not signed in yet

      await client.post(
        ApiEndpoints.pushRegister,
        // The server accepts only "web" or "app" and 400s on anything else.
        data: {'token': token, 'platform': 'app'},
      );
      debugPrint('🔔 [FCM] Device token registered with backend');
    } catch (e) {
      // A failed registration must never block sign-in; the next refresh or
      // app launch retries.
      debugPrint('⚠️ [FCM] Token registration failed: $e');
    }
  }

  /// Detaches this device from the account so a signed-out phone stops
  /// receiving the previous customer's parcel notifications.
  Future<void> removeTokenFromBackend() async {
    if (!isConfigured) return;
    final token = fcmToken ?? await _readToken();
    if (token == null || token.isEmpty) return;
    try {
      final client = ApiClient.createDefault();
      await client.delete(ApiEndpoints.pushRemove, data: {'token': token});
      debugPrint('🔔 [FCM] Device token removed from backend');
    } catch (e) {
      debugPrint('⚠️ [FCM] Token removal failed: $e');
    }
  }

  Future<String?> _readToken() async {
    try {
      // iOS needs an APNS token before getToken() will resolve.
      if (Platform.isIOS) {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns == null) return null;
      }
      fcmToken = await FirebaseMessaging.instance.getToken();
      return fcmToken;
    } catch (_) {
      return null;
    }
  }

  /// Show custom local heads-up notification banner
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'sungguard_high_importance_channel',
      'High Importance Notifications',
      channelDescription:
          'This channel is used for important parcel & delivery notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}
