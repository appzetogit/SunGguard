import 'core/config/app_environment.dart';
import 'main.dart';

/// Entry point for STAGING environment
void main() async {
  await bootstrapApp(AppEnvironment.staging);
}
