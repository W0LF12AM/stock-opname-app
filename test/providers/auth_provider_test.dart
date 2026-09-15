import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_opname_app/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider Tests', () {
    test('Initial state is unauthenticated when no token stored', () async {
      SharedPreferences.setMockInitialValues({});

      final auth = AuthProvider();
      await auth.checkLoginStatus();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.username, isNull);
      expect(auth.fullName, isNull);
      expect(auth.role, isNull);
      expect(auth.userId, isNull);
      print('  ✓ [SUCCESS] Unauthenticated state verified on empty SharedPreferences');
    });

    test('checkLoginStatus restores session if token exists', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'dummy_token_123',
        'username': 'admin_kapal',
        'full_name': 'Chief Engineer Budi',
        'role': 'chief_engineer',
        'user_id': 12,
      });

      final auth = AuthProvider();
      await auth.checkLoginStatus();

      expect(auth.isAuthenticated, isTrue);
      expect(auth.username, 'admin_kapal');
      expect(auth.fullName, 'Chief Engineer Budi');
      expect(auth.role, 'chief_engineer');
      expect(auth.userId, 12);
      print('  ✓ [SUCCESS] Session restored: ${auth.fullName} (${auth.role})');
    });

    test('Offline login succeeds with correct cached credentials', () async {
      SharedPreferences.setMockInitialValues({
        'username': 'inspector1',
        'password_hash': 'secret123',
        'full_name': 'Inspector Satu',
        'role': 'inspector',
        'user_id': 5,
      });

      final auth = AuthProvider();
      await auth.login('inspector1', 'secret123', false);

      expect(auth.isAuthenticated, isTrue);
      expect(auth.username, 'inspector1');
      expect(auth.fullName, 'Inspector Satu');
      expect(auth.role, 'inspector');
      expect(auth.userId, 5);
      print('  ✓ [SUCCESS] Offline login succeeded for user "${auth.username}"');
    });

    test('Offline login fails when no cached credentials exist', () async {
      SharedPreferences.setMockInitialValues({});

      final auth = AuthProvider();

      expect(
        () => auth.login('user', 'pass', false),
        throwsA(
          predicate(
            (e) =>
                e.toString().contains('Koneksi internet diperlukan') ||
                e is Exception,
          ),
        ),
      );
      expect(auth.isAuthenticated, isFalse);
      print('  ✓ [SUCCESS] Offline login blocked when no credentials stored');
    });

    test('Offline login fails when credentials do not match', () async {
      SharedPreferences.setMockInitialValues({
        'username': 'inspector1',
        'password_hash': 'correct_password',
      });

      final auth = AuthProvider();

      expect(
        () => auth.login('inspector1', 'wrong_password', false),
        throwsA(
          predicate(
            (e) =>
                e.toString().contains('Kredensial offline tidak cocok') ||
                e is Exception,
          ),
        ),
      );
      expect(auth.isAuthenticated, isFalse);
      print('  ✓ [SUCCESS] Offline login rejected wrong password correctly');
    });

    test('logout clears preferences and resets state', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'test_token',
        'username': 'crew_deck',
        'full_name': 'Crew Deck Hand',
        'role': 'crew',
        'user_id': 8,
      });

      final auth = AuthProvider();
      await auth.checkLoginStatus();
      expect(auth.isAuthenticated, isTrue);

      await auth.logout();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.username, isNull);
      expect(auth.fullName, isNull);
      expect(auth.role, isNull);
      expect(auth.userId, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      print('  ✓ [SUCCESS] Logout successfully wiped session & preferences');
    });
  });
}
