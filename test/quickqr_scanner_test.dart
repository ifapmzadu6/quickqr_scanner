import 'package:flutter_test/flutter_test.dart';
import 'package:quickqr_scanner/quickqr_scanner.dart';
import 'package:quickqr_scanner/quickqr_scanner_platform_interface.dart';
import 'package:quickqr_scanner/quickqr_scanner_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockQuickqrScannerPlatform
    with MockPlatformInterfaceMixin
    implements QuickqrScannerPlatform {

  @override
  Future<Map<String, dynamic>> checkAvailability() => Future.value({'isSupported': true, 'isAvailable': true});

  @override
  Stream<QRScanResult> get onQRDetected => Stream.empty();

  @override
  Future<Map<String, dynamic>> checkPermissions() => Future.value({'status': 'granted'});

  @override
  Future<Map<String, dynamic>> requestPermissions() => Future.value({'granted': true});

  @override
  Future<Map<String, dynamic>> initialize([QRScanConfig? config]) => Future.value({'success': true});

  @override
  Future<void> startScanning() => Future.value();

  @override
  Future<void> stopScanning() => Future.value();

  @override
  Future<void> dispose() => Future.value();

  @override
  Future<Map<String, dynamic>> toggleFlashlight() => Future.value({'isOn': false});

  @override
  Future<QRScanResult?> scanFromImage(String imagePath) => Future.value(null);
}

void main() {
  final QuickqrScannerPlatform initialPlatform = QuickqrScannerPlatform.instance;

  test('$MethodChannelQuickqrScanner is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelQuickqrScanner>());
  });

  test('checkAvailability', () async {
    final scanner = QuickQRScanner.instance;
    MockQuickqrScannerPlatform fakePlatform = MockQuickqrScannerPlatform();
    QuickqrScannerPlatform.instance = fakePlatform;

    final result = await scanner.checkAvailability();
    expect(result['isSupported'], true);
    expect(result['isAvailable'], true);
  });
}
