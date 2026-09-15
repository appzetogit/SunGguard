import 'core/config/app_environment.dart';
import 'main.dart';

/// Entry point for DEVELOPMENT environment
void main() async {
  await bootstrapApp(AppEnvironment.dev);
}
