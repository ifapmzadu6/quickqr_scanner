// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing


import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:quickqr_scanner/quickqr_scanner.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('checkAvailability test', (WidgetTester tester) async {
    final scanner = QuickQRScanner.instance;
    final availability = await scanner.checkAvailability();
    // Check that device availability returns expected structure
    expect(availability.containsKey('isSupported'), true);
    expect(availability.containsKey('isAvailable'), true);
    expect(availability['isSupported'], true);
  });
}
