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

  // MARK: - Camera Control Methods
  @override
  Future<Map<String, dynamic>> setZoomLevel(double zoomLevel) => Future.value({
    'success': true,
    'currentZoom': zoomLevel,
    'maxZoom': 10.0,
  });

  @override
  Future<Map<String, dynamic>> getZoomCapabilities() => Future.value({
    'currentZoom': 1.0,
    'minZoom': 1.0,
    'maxZoom': 10.0,
    'supportsOpticalZoom': false,
  });

  @override
  Future<Map<String, dynamic>> setFocusMode(FocusMode focusMode, [FocusPoint? focusPoint]) => Future.value({
    'success': true,
    'focusMode': focusMode.value,
    'focusPoint': focusPoint?.toMap(),
  });

  @override
  Future<Map<String, dynamic>> setMacroMode(bool enabled) => Future.value({
    'success': true,
    'enabled': enabled,
    'supported': true,
  });

  @override
  Future<Map<String, dynamic>> setExposureMode(ExposureMode exposureMode, [double? exposureCompensation]) => Future.value({
    'success': true,
    'exposureMode': exposureMode.value,
    'exposureCompensation': exposureCompensation,
  });

  @override
  Future<Map<String, dynamic>> setCameraResolution(CameraResolution resolution) => Future.value({
    'success': true,
    'resolution': resolution.value,
    'actualSize': {'width': 1920, 'height': 1080},
  });

  @override
  Future<Map<String, dynamic>> switchCamera(CameraPosition position) => Future.value({
    'success': true,
    'position': position.value,
    'available': ['back', 'front'],
  });

  @override
  Future<Map<String, dynamic>> setImageStabilization(bool enabled) => Future.value({
    'success': true,
    'enabled': enabled,
    'supported': true,
  });

  @override
  Future<Map<String, dynamic>> setWhiteBalanceMode(WhiteBalanceMode whiteBalanceMode) => Future.value({
    'success': true,
    'whiteBalanceMode': whiteBalanceMode.value,
    'supported': ['auto', 'daylight', 'cloudy', 'tungsten', 'fluorescent'],
  });

  @override
  Future<Map<String, dynamic>> setFrameRate(int frameRate) => Future.value({
    'success': true,
    'frameRate': frameRate,
    'supportedRanges': [{'min': 15.0, 'max': 30.0}, {'min': 30.0, 'max': 60.0}],
  });

  @override
  Future<Map<String, dynamic>> setHDRMode(bool enabled) => Future.value({
    'success': true,
    'enabled': enabled,
    'supported': true,
  });

  @override
  Future<Map<String, dynamic>> getCameraCapabilities() => Future.value({
    'zoom': {
      'currentZoom': 1.0,
      'minZoom': 1.0,
      'maxZoom': 10.0,
      'supportsOpticalZoom': false,
    },
    'focus': {
      'currentMode': 'auto',
      'supportedModes': ['auto', 'manual', 'infinity', 'macro'],
      'supportsPointOfInterest': true,
    },
    'exposure': {
      'currentMode': 'auto',
      'supportedModes': ['auto', 'manual'],
      'minBias': -2.0,
      'maxBias': 2.0,
    },
    'features': {
      'macroMode': true,
      'stabilization': true,
      'hdr': true,
      'flashlight': true,
      'whiteBalance': true,
    },
  });

  @override
  Future<Map<String, dynamic>> getMacroModeState() => Future.value({
    'enabled': false,
    'supported': true,
  });

  @override
  Future<Map<String, dynamic>> getFocusState() => Future.value({
    'focusMode': 'auto',
    'focusPoint': null,
    'supportedModes': ['auto', 'manual', 'infinity', 'macro'],
  });

  @override
  Future<Map<String, dynamic>> getExposureState() => Future.value({
    'exposureMode': 'auto',
    'exposureCompensation': 0.0,
    'supportedModes': ['auto', 'manual'],
  });

  @override
  Future<Map<String, dynamic>> getCameraResolutionState() => Future.value({
    'resolution': 'high',
    'actualSize': {'width': 1920, 'height': 1080},
    'supported': ['low', 'medium', 'high', 'ultra'],
  });

  @override
  Future<Map<String, dynamic>> getImageStabilizationState() => Future.value({
    'enabled': false,
    'supported': true,
  });

  @override
  Future<Map<String, dynamic>> getWhiteBalanceState() => Future.value({
    'whiteBalanceMode': 'auto',
    'supported': ['auto', 'daylight', 'cloudy', 'tungsten', 'fluorescent'],
  });

  @override
  Future<Map<String, dynamic>> getFrameRateState() => Future.value({
    'frameRate': 30,
    'supportedRanges': [{'min': 15.0, 'max': 30.0}, {'min': 30.0, 'max': 60.0}],
  });

  @override
  Future<Map<String, dynamic>> getHDRState() => Future.value({
    'enabled': false,
    'supported': true,
  });

  @override
  Future<Map<String, dynamic>> applyCameraControlConfig(CameraControlConfig config) => Future.value({
    'success': true,
    'applied': {
      'zoom': true,
      'macroMode': true,
      'focusMode': true,
    },
    'warnings': <String>[],
  });

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

    group('Camera Control Features', () {
      test('setZoomLevel works correctly', () async {
        final result = await scanner.setZoomLevel(2.5);
        expect(result['success'], isTrue);
        expect(result['currentZoom'], 2.5);
        expect(result['maxZoom'], 10.0);
      });

      test('getZoomCapabilities returns zoom information', () async {
        final result = await scanner.getZoomCapabilities();
        expect(result['currentZoom'], 1.0);
        expect(result['minZoom'], 1.0);
        expect(result['maxZoom'], 10.0);
        expect(result.containsKey('supportsOpticalZoom'), isTrue);
      });

      test('setMacroMode enables/disables macro mode', () async {
        var result = await scanner.setMacroMode(true);
        expect(result['success'], isTrue);
        expect(result['enabled'], isTrue);
        expect(result['supported'], isTrue);

        result = await scanner.setMacroMode(false);
        expect(result['success'], isTrue);
        expect(result['enabled'], isFalse);
      });

      test('setFocusMode works with different modes', () async {
        final result = await scanner.setFocusMode(FocusMode.manual, FocusPoint(0.5, 0.5));
        expect(result['success'], isTrue);
        expect(result['focusMode'], 'manual');
        expect(result['focusPoint'], isNotNull);
      });

      test('getCameraCapabilities returns comprehensive information', () async {
        final result = await scanner.getCameraCapabilities();
        expect(result.containsKey('zoom'), isTrue);
        expect(result.containsKey('focus'), isTrue);
        expect(result.containsKey('exposure'), isTrue);
        expect(result.containsKey('features'), isTrue);
      });

      test('applyCameraControlConfig applies configuration', () async {
        final config = CameraControlConfig.macro();
        final result = await scanner.applyCameraControlConfig(config);
        expect(result['success'], isTrue);
        expect(result.containsKey('applied'), isTrue);
        expect(result.containsKey('warnings'), isTrue);
      });

      test('state getter methods work correctly', () async {
        var result = await scanner.getMacroModeState();
        expect(result.containsKey('enabled'), isTrue);
        expect(result.containsKey('supported'), isTrue);

        result = await scanner.getFocusState();
        expect(result.containsKey('focusMode'), isTrue);
        expect(result.containsKey('supportedModes'), isTrue);

        result = await scanner.getExposureState();
        expect(result.containsKey('exposureMode'), isTrue);
        expect(result.containsKey('supportedModes'), isTrue);

        result = await scanner.getCameraResolutionState();
        expect(result.containsKey('resolution'), isTrue);
        expect(result.containsKey('actualSize'), isTrue);
        expect(result.containsKey('supported'), isTrue);

        result = await scanner.getImageStabilizationState();
        expect(result.containsKey('enabled'), isTrue);
        expect(result.containsKey('supported'), isTrue);

        result = await scanner.getWhiteBalanceState();
        expect(result.containsKey('whiteBalanceMode'), isTrue);
        expect(result.containsKey('supported'), isTrue);

        result = await scanner.getFrameRateState();
        expect(result.containsKey('frameRate'), isTrue);
        expect(result.containsKey('supportedRanges'), isTrue);

        result = await scanner.getHDRState();
        expect(result.containsKey('enabled'), isTrue);
        expect(result.containsKey('supported'), isTrue);
      });

      test('camera control settings work correctly', () async {
        var result = await scanner.setExposureMode(ExposureMode.manual, -0.5);
        expect(result['success'], isTrue);
        expect(result['exposureMode'], 'manual');
        expect(result['exposureCompensation'], -0.5);

        result = await scanner.setCameraResolution(CameraResolution.high);
        expect(result['success'], isTrue);
        expect(result['resolution'], 'high');
        expect(result.containsKey('actualSize'), isTrue);

        result = await scanner.switchCamera(CameraPosition.front);
        expect(result['success'], isTrue);
        expect(result['position'], 'front');
        expect(result.containsKey('available'), isTrue);

        result = await scanner.setImageStabilization(true);
        expect(result['success'], isTrue);
        expect(result['enabled'], isTrue);
        expect(result['supported'], isTrue);

        result = await scanner.setWhiteBalanceMode(WhiteBalanceMode.daylight);
        expect(result['success'], isTrue);
        expect(result['whiteBalanceMode'], 'daylight');
        expect(result.containsKey('supported'), isTrue);

        result = await scanner.setFrameRate(60);
        expect(result['success'], isTrue);
        expect(result['frameRate'], 60);
        expect(result.containsKey('supportedRanges'), isTrue);

        result = await scanner.setHDRMode(true);
        expect(result['success'], isTrue);
        expect(result['enabled'], isTrue);
        expect(result['supported'], isTrue);
      });
    });
  });
}
