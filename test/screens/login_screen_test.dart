import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_opname_app/providers/auth_provider.dart';
import 'package:stock_opname_app/providers/connectivity_provider.dart';
import 'package:stock_opname_app/screens/login_screen.dart';

Widget createTestableLoginScreen() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
    ],
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Renders all main UI components on LoginScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableLoginScreen());
      await tester.pump();

      expect(find.text('STOCK OPNAME'), findsOneWidget);
      expect(find.text('Sistem Inventaris Kapal Offline'), findsOneWidget);
      expect(find.text('Masuk Akun'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_rounded), findsOneWidget);
      print('  ✓ [SUCCESS] LoginScreen rendered all inputs and headers');
    });

    testWidgets('Shows validation error when submitting empty fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableLoginScreen());
      await tester.pump();

      // Tap 'Masuk' button without filling the form
      await tester.tap(find.text('Masuk'));
      await tester.pump();

      expect(find.text('Username tidak boleh kosong'), findsOneWidget);
      print('  ✓ [SUCCESS] Login validation triggered for empty credentials');
    });

    testWidgets('Toggles password visibility icon when clicked', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableLoginScreen());
      await tester.pump();

      // Initially obscured -> shows visibility_outlined or visibility_off_outlined
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap the eye icon button
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // Now toggled to visible -> icon changes
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      print('  ✓ [SUCCESS] Password visibility icon successfully toggled');
    });
  });
}
