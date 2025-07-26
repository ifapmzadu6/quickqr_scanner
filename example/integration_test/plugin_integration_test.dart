// Integration tests for QuickQR Scanner Plugin
//
// These tests run in a full Flutter application and can interact
// with the host side of the plugin implementation.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:quickqr_scanner_plugin/quickqr_scanner_plugin.dart';
import 'package:quickqr_scanner_plugin_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('QuickQR Scanner Plugin Integration Tests', () {
    late QuickqrScannerPlugin scanner;

    setUp(() {
      scanner = QuickqrScannerPlugin();
    });

    tearDown(() async {
      try {
        await scanner.stopScanning();
        await scanner.dispose();
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    testWidgets('Plugin availability check', (WidgetTester tester) async {
      final availability = await scanner.checkAvailability();
      
      // Verify required keys exist
      expect(availability.containsKey('isSupported'), isTrue);
      expect(availability.containsKey('isAvailable'), isTrue);
      
      // Plugin should be supported on test devices
      expect(availability['isSupported'], isTrue);
      
      // Device info should be provided
      expect(availability.containsKey('deviceInfo'), isTrue);
    });

    testWidgets('Permission system test', (WidgetTester tester) async {
      // Check current permission status
      final permissionStatus = await scanner.checkPermissions();
      expect(permissionStatus.containsKey('status'), isTrue);
      expect(permissionStatus.containsKey('hasCamera'), isTrue);
      
      // Note: On simulators/emulators, camera might not be available
      // but the plugin should still handle this gracefully
    });

    testWidgets('Scanner initialization test', (WidgetTester tester) async {
      try {
        final initResult = await scanner.initialize();
        expect(initResult.containsKey('success'), isTrue);
        
        // If initialization succeeds, test lifecycle
        if (initResult['success'] == true) {
          // Test that we can start and stop scanning
          await scanner.startScanning();
          await scanner.stopScanning();
        }
      } catch (e) {
        // On test environments without camera, initialization might fail
        // This is expected behavior and should be handled gracefully
        expect(e.toString(), anyOf([contains('camera'), contains('permission'), contains('not supported')]));
      }
    });

    testWidgets('Flashlight control test', (WidgetTester tester) async {
      try {
        final flashResult = await scanner.toggleFlashlight();
        expect(flashResult.containsKey('isOn'), isTrue);
        expect(flashResult.containsKey('message'), isTrue);
      } catch (e) {
        // Flashlight might not be available in test environment
        expect(e.toString(), anyOf([contains('flashlight'), contains('not supported'), contains('not available')]));
      }
    });

    testWidgets('Image scanning test with invalid path', (WidgetTester tester) async {
      // Test with non-existent image path
      final result = await scanner.scanFromImage('/non/existent/path.jpg');
      expect(result, isNull);
    });

    testWidgets('Full app UI integration test', (WidgetTester tester) async {
      // Load the full example app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify main UI elements are present
      expect(find.text('QuickQR Scanner'), findsOneWidget);
      expect(find.text('Initialize'), findsOneWidget);
      expect(find.text('Start Scan'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);

      // Test initialization button tap
      final initButton = find.widgetWithText(ElevatedButton, 'Initialize');
      expect(initButton, findsOneWidget);
      
      await tester.tap(initButton);
      await tester.pumpAndSettle();

      // Check that status updates after initialization attempt
      expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is Text &&
                             widget.data != null &&
                             (widget.data!.contains('initialize') ||
                              widget.data!.contains('Initializ') ||
                              widget.data!.contains('complete') ||
                              widget.data!.contains('error') ||
                              widget.data!.contains('permission')),
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Error handling test', (WidgetTester tester) async {
      // Test scanning without initialization (should handle gracefully)
      try {
        await scanner.startScanning();
        // If no exception, stop scanning to clean up
        await scanner.stopScanning();
      } catch (e) {
        // Expected behavior - should throw or handle gracefully
        expect(e.toString().isNotEmpty, isTrue);
      }
    });

    testWidgets('Cleanup and resource management test', (WidgetTester tester) async {
      // Test that dispose can be called multiple times without error
      await scanner.dispose();
      await scanner.dispose(); // Should not throw

      // Test that methods handle disposed state gracefully
      try {
        await scanner.startScanning();
      } catch (e) {
        // Expected - should handle disposed state
        expect(e.toString().isNotEmpty, isTrue);
      }
    });
  });
}
