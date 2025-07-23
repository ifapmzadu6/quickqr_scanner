import 'package:flutter_test/flutter_test.dart';
import 'package:quickqr_scanner_plugin/quickqr_scanner_plugin.dart';
import 'package:quickqr_scanner_plugin/quickqr_scanner_platform_interface.dart';
import 'package:quickqr_scanner_plugin/quickqr_scanner_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:async';

class MockQuickqrScannerPlatform
    with MockPlatformInterfaceMixin
    implements QuickqrScannerPlatform {

  bool _isInitialized = false;
  bool _isScanning = false;
  bool _flashlightOn = false;
  final StreamController<QRScanResult> _scanController = StreamController<QRScanResult>.broadcast();

  @override
  Future<Map<String, dynamic>> checkAvailability() => Future.value({
    'isSupported': true, 
    'isAvailable': true,
    'deviceInfo': {
      'framework': 'Test Framework',
      'hasCamera': true,
    }
  });

  @override
  Stream<QRScanResult> get onQRDetected => _scanController.stream;

  @override
  Future<Map<String, dynamic>> checkPermissions() => Future.value({
    'status': 'granted',
    'canRequest': true,
    'hasCamera': true,
  });

  @override
  Future<Map<String, dynamic>> requestPermissions() => Future.value({
    'granted': true,
    'status': 'granted',
  });

  @override
  Future<Map<String, dynamic>> initialize([QRScanConfig? config]) {
    _isInitialized = true;
    return Future.value({'success': true, 'message': 'Scanner initialized'});
  }

  @override
  Future<void> startScanning() {
    if (!_isInitialized) throw Exception('Scanner not initialized');
    _isScanning = true;
    return Future.value();
  }

  @override
  Future<void> stopScanning() {
    _isScanning = false;
    return Future.value();
  }

  @override
  Future<void> dispose() {
    _isInitialized = false;
    _isScanning = false;
    _scanController.close();
    return Future.value();
  }

  @override
  Future<Map<String, dynamic>> toggleFlashlight() {
    _flashlightOn = !_flashlightOn;
    return Future.value({
      'isOn': _flashlightOn,
      'message': _flashlightOn ? 'Flashlight on' : 'Flashlight off',
    });
  }

  @override
  Future<QRScanResult?> scanFromImage(String imagePath) {
    if (imagePath.contains('valid_qr')) {
      return Future.value(QRScanResult(
        content: 'https://example.com',
        format: BarcodeFormat.qr,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        confidence: 0.95,
      ));
    }
    return Future.value(null);
  }

  // Test helper methods
  void simulateScanResult(QRScanResult result) {
    if (_isScanning) {
      _scanController.add(result);
    }
  }

  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  bool get flashlightOn => _flashlightOn;
}

void main() {
  final QuickqrScannerPlatform initialPlatform = QuickqrScannerPlatform.instance;

  group('QuickQR Scanner Plugin Tests', () {
    late MockQuickqrScannerPlatform mockPlatform;
    late QuickqrScannerPlugin scanner;

    setUp(() {
      mockPlatform = MockQuickqrScannerPlatform();
      QuickqrScannerPlatform.instance = mockPlatform;
      scanner = QuickqrScannerPlugin();
    });

    tearDown(() {
      QuickqrScannerPlatform.instance = initialPlatform;
    });

    test('uses MethodChannelQuickqrScanner as default platform implementation', () {
      expect(initialPlatform, isInstanceOf<MethodChannelQuickqrScanner>());
    });

    group('Device availability', () {
      test('checkAvailability returns device capabilities', () async {
        final result = await scanner.checkAvailability();
        expect(result['isSupported'], isTrue);
        expect(result['isAvailable'], isTrue);
        expect(result['deviceInfo'], isNotNull);
        expect(result['deviceInfo']['hasCamera'], isTrue);
      });
    });

    group('Permissions', () {
      test('checkPermissions returns permission status', () async {
        final result = await scanner.checkPermissions();
        expect(result['status'], 'granted');
        expect(result['hasCamera'], isTrue);
      });

      test('requestPermissions returns grant result', () async {
        final result = await scanner.requestPermissions();
        expect(result['granted'], isTrue);
        expect(result['status'], 'granted');
      });
    });

    group('Scanner lifecycle', () {
      test('initialize prepares scanner for use', () async {
        final result = await scanner.initialize();
        expect(result['success'], isTrue);
        expect(mockPlatform.isInitialized, isTrue);
      });

      test('startScanning requires initialization', () async {
        expect(() => scanner.startScanning(), throwsException);
      });

      test('startScanning works after initialization', () async {
        await scanner.initialize();
        await scanner.startScanning();
        expect(mockPlatform.isScanning, isTrue);
      });

      test('stopScanning stops active scanning', () async {
        await scanner.initialize();
        await scanner.startScanning();
        await scanner.stopScanning();
        expect(mockPlatform.isScanning, isFalse);
      });

      test('dispose cleans up resources', () async {
        await scanner.initialize();
        await scanner.dispose();
        expect(mockPlatform.isInitialized, isFalse);
      });
    });

    group('Flashlight control', () {
      test('toggleFlashlight changes flashlight state', () async {
        var result = await scanner.toggleFlashlight();
        expect(result['isOn'], isTrue);
        expect(result['message'], contains('on'));

        result = await scanner.toggleFlashlight();
        expect(result['isOn'], isFalse);
        expect(result['message'], contains('off'));
      });
    });

    group('Image scanning', () {
      test('scanFromImage returns null for invalid image', () async {
        final result = await scanner.scanFromImage('/invalid/path.jpg');
        expect(result, isNull);
      });

      test('scanFromImage returns result for valid QR image', () async {
        final result = await scanner.scanFromImage('/path/valid_qr.jpg');
        expect(result, isNotNull);
        expect(result!.content, 'https://example.com');
        expect(result.format, BarcodeFormat.qr);
        expect(result.confidence, 0.95);
      });
    });

    group('Real-time scanning', () {
      test('onQRDetected stream receives scan results', () async {
        await scanner.initialize();
        await scanner.startScanning();

        final scanResult = QRScanResult(
          content: 'Test QR Content',
          format: BarcodeFormat.qr,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          confidence: 0.9,
        );

        final streamFuture = scanner.onQRDetected.first;
        mockPlatform.simulateScanResult(scanResult);

        final receivedResult = await streamFuture;
        expect(receivedResult.content, scanResult.content);
        expect(receivedResult.format, scanResult.format);
      });

      test('onQRDetected stream does not receive results when not scanning', () async {
        await scanner.initialize();
        // Don't start scanning

        bool receivedResult = false;
        final subscription = scanner.onQRDetected.listen((_) {
          receivedResult = true;
        });

        final scanResult = QRScanResult(
          content: 'Test QR Content',
          format: BarcodeFormat.qr,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          confidence: 0.9,
        );

        mockPlatform.simulateScanResult(scanResult);
        
        // Wait a bit to ensure no result is received
        await Future.delayed(const Duration(milliseconds: 100));
        expect(receivedResult, isFalse);

        await subscription.cancel();
      });
    });
  });
}
