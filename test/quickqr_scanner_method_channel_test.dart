import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickqr_scanner_plugin/quickqr_scanner_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelQuickqrScanner platform = MethodChannelQuickqrScanner();
  const MethodChannel channel = MethodChannel('quickqr_scanner');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'checkAvailability':
            return {
              'isSupported': true,
              'isAvailable': true,
              'deviceInfo': {
                'framework': 'Vision/MLKit',
                'hasCamera': true,
              }
            };
          case 'checkPermissions':
            return {
              'status': 'granted',
              'canRequest': true,
              'hasCamera': true,
            };
          case 'requestPermissions':
            return {
              'granted': true,
              'status': 'granted',
            };
          case 'initialize':
            return {
              'success': true,
              'message': 'Scanner initialized',
            };
          case 'toggleFlashlight':
            return {
              'isOn': false,
              'message': 'Flashlight off',
            };
          case 'startScanning':
          case 'stopScanning':
          case 'dispose':
            return null;
          case 'scanFromImage':
            return null; // No QR code found in test image
          default:
            throw PlatformException(
              code: 'UNIMPLEMENTED',
              message: 'Method ${methodCall.method} not implemented in test',
            );
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  group('MethodChannelQuickqrScanner tests', () {
    test('checkAvailability returns expected structure', () async {
      final result = await platform.checkAvailability();
      expect(result, isA<Map<String, dynamic>>());
      expect(result['isSupported'], isTrue);
      expect(result['isAvailable'], isTrue);
      expect(result['deviceInfo'], isNotNull);
    });

    test('checkPermissions returns expected structure', () async {
      final result = await platform.checkPermissions();
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('status'), isTrue);
      expect(result.containsKey('hasCamera'), isTrue);
    });

    test('requestPermissions returns expected structure', () async {
      final result = await platform.requestPermissions();
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('granted'), isTrue);
      expect(result.containsKey('status'), isTrue);
    });

    test('initialize returns expected structure', () async {
      final result = await platform.initialize();
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });

    test('toggleFlashlight returns expected structure', () async {
      final result = await platform.toggleFlashlight();
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('isOn'), isTrue);
      expect(result.containsKey('message'), isTrue);
    });

    test('scanFromImage handles file not found', () async {
      try {
        final result = await platform.scanFromImage('/fake/path.jpg');
        expect(result, isNull);
      } catch (e) {
        // Should handle file not found gracefully
        expect(e.toString().contains('not found') || e.toString().contains('FILE_NOT_FOUND'), isTrue);
      }
    });

    test('lifecycle methods complete without error', () async {
      expect(() => platform.startScanning(), returnsNormally);
      expect(() => platform.stopScanning(), returnsNormally);
      expect(() => platform.dispose(), returnsNormally);
    });
  });
}
