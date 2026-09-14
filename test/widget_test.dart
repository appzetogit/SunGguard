import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sungguard/app/app.dart';
import 'package:sungguard/core/di/injection.dart';

void main() {
  testWidgets('SunGguardApp smoke test', (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    await initDependencies();

    await tester.pumpWidget(const SunGguardApp());

    expect(find.byType(SunGguardApp), findsOneWidget);
  });
}
