import 'dart:async';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'quickqr_scanner_method_channel.dart';
import 'src/models/qr_scan_result.dart';
import 'src/models/qr_scan_config.dart';

abstract class QuickqrScannerPlatform extends PlatformInterface {
  /// Constructs a QuickqrScannerPlatform.
  QuickqrScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static QuickqrScannerPlatform _instance = MethodChannelQuickqrScanner();

  /// The default instance of [QuickqrScannerPlatform] to use.
  ///
  /// Defaults to [MethodChannelQuickqrScanner].
  static QuickqrScannerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [QuickqrScannerPlatform] when
  /// they register themselves.
  static set instance(QuickqrScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Stream for receiving QR scan results
  Stream<QRScanResult> get onQRDetected {
    throw UnimplementedError('onQRDetected has not been implemented.');
  }

  /// Check device availability for QR scanning
  Future<Map<String, dynamic>> checkAvailability() {
    throw UnimplementedError('checkAvailability() has not been implemented.');
  }

  /// Check camera permissions
  Future<Map<String, dynamic>> checkPermissions() {
    throw UnimplementedError('checkPermissions() has not been implemented.');
  }

  /// Request camera permissions
  Future<Map<String, dynamic>> requestPermissions() {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }

  /// Initialize the QR scanner
  Future<Map<String, dynamic>> initialize([QRScanConfig? config]) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Start real-time QR scanning
  Future<void> startScanning() {
    throw UnimplementedError('startScanning() has not been implemented.');
  }

  /// Stop QR scanning
  Future<void> stopScanning() {
    throw UnimplementedError('stopScanning() has not been implemented.');
  }

  /// Dispose the scanner
  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  /// Toggle flashlight
  Future<Map<String, dynamic>> toggleFlashlight() {
    throw UnimplementedError('toggleFlashlight() has not been implemented.');
  }

  /// Scan QR code from image file
  Future<QRScanResult?> scanFromImage(String imagePath) {
    throw UnimplementedError('scanFromImage() has not been implemented.');
  }
}
