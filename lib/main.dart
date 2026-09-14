import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'core/config/app_environment.dart';
import 'core/di/injection.dart';
import 'core/services/firebase_notification_service.dart';

/// Bootstrap the Flutter app with initialized environment configuration
Future<void> bootstrapApp(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment config
  AppConfig.initialize(environment);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase App & Push Notifications
  await FirebaseNotificationService().initialize();

  // Initialize all dependencies via GetIt Service Locator
  await initDependencies();

  runApp(const SunGguardApp());
}

/// Fallback entry point (Defaults to Production environment if run without flavor target)
void main() async {
  await bootstrapApp(AppEnvironment.prod);
}
