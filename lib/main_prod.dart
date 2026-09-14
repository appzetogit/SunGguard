import 'core/config/app_environment.dart';
import 'main.dart';

/// Entry point for PRODUCTION environment
void main() async {
  await bootstrapApp(AppEnvironment.prod);
}
