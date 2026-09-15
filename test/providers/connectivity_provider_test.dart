import 'package:flutter_test/flutter_test.dart';
import 'package:stock_opname_app/providers/connectivity_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityProvider Tests', () {
    test('Default status is online', () {
      final connectivity = ConnectivityProvider();
      expect(connectivity.isOnline, isTrue);
      print('  ✓ [SUCCESS] ConnectivityProvider default online state: ${connectivity.isOnline}');
    });
  });
}
