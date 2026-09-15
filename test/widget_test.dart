import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_opname_app/main.dart';

void main() {
  testWidgets('App smoke test: renders app and transitions to LoginScreen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify initial splash screen header
    expect(find.text('Stock Opname'), findsOneWidget);

    // Pump through logo & text animation
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 700));

    // Pump through 1.5s sequence timer and 2.0s warmup delay
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(seconds: 2));

    // Allow page transition animation to complete
    await tester.pumpAndSettle();

    // Verify transition to LoginScreen
    expect(find.text('STOCK OPNAME'), findsOneWidget);
    expect(find.text('Masuk Akun'), findsOneWidget);
    print('  ✓ [SUCCESS] MyApp smoke test: SplashScreen rendered and completed navigation to LoginScreen');
  });
}
