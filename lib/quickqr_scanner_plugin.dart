/// High-performance QR scanner with Vision framework integration for iOS and ML Kit for Android
/// 
/// This plugin provides enterprise-grade QR code scanning with:
library quickqr_scanner_plugin;
/// - Real-time QR code scanning using device camera with native performance
/// - Image-based QR code scanning from files without picker dependency
/// - Vision framework integration for iOS (hardware acceleration on supported devices)
/// - ML Kit integration for Android (Google ML optimization)
/// - Platform Views for seamless Flutter integration
/// - Comprehensive error handling and resource management
/// 
/// Usage:
/// ```dart
/// import 'package:quickqr_scanner_plugin/quickqr_scanner_plugin.dart';
/// 
/// // Initialize scanner
/// final scanner = QuickqrScannerPlugin();
/// await scanner.initialize();
/// 
/// // Listen to scan results
/// scanner.onQRDetected.listen((result) {
///   print('QR Code: ${result.content}');
/// });
/// 
/// // Start scanning
/// await scanner.startScanning();
/// 
/// // Scan from image  
/// final result = await scanner.scanFromImage('/path/to/image.jpg');
/// ```

import 'dart:async';

import 'quickqr_scanner_platform_interface.dart';
import 'src/models/qr_scan_result.dart';
import 'src/models/qr_scan_config.dart';

export 'src/models/qr_scan_result.dart';
export 'src/models/qr_scan_config.dart';
export 'src/models/scanner_exception.dart';

/// The main plugin class for QR scanning functionality
/// 
/// This class provides methods for QR code scanning using native platform
/// implementations with VisionKit on iOS and ML Kit on Android.
class QuickqrScannerPlugin {
  /// Creates a new instance of the scanner plugin
  QuickqrScannerPlugin();

  /// Stream for receiving QR scan results
  Stream<QRScanResult> get onQRDetected {
    return QuickqrScannerPlatform.instance.onQRDetected;
  }

  /// Check if the device supports QR scanning
  /// 
  /// Returns information about device capabilities including:
  /// - Whether scanning is supported
  /// - Available camera
  /// - Supported formats
  /// - Device info
  Future<Map<String, dynamic>> checkAvailability() {
    return QuickqrScannerPlatform.instance.checkAvailability();
  }

  /// Check camera permissions
  /// 
  /// Returns information about permission status:
  /// - status: 'granted', 'denied', 'notDetermined', 'restricted'
  /// - canRequest: whether permission can be requested
  /// - hasCamera: whether device has camera
  Future<Map<String, dynamic>> checkPermissions() {
    return QuickqrScannerPlatform.instance.checkPermissions();
  }

  /// Request camera permissions
  /// 
  /// Returns:
  /// - granted: whether permission was granted
  /// - status: final permission status
  Future<Map<String, dynamic>> requestPermissions() {
    return QuickqrScannerPlatform.instance.requestPermissions();
  }

  /// Initialize the QR scanner
  /// 
  /// Must be called before starting scanning operations.
  /// Configures camera and prepares for scanning.
  Future<Map<String, dynamic>> initialize([QRScanConfig? config]) {
    return QuickqrScannerPlatform.instance.initialize(config);
  }

  /// Start real-time QR scanning
  /// 
  /// Begins camera preview and QR detection.
  /// Results will be delivered via [onQRDetected] stream.
  Future<void> startScanning() {
    return QuickqrScannerPlatform.instance.startScanning();
  }

  /// Stop QR scanning
  /// 
  /// Stops camera preview and QR detection.
  Future<void> stopScanning() {
    return QuickqrScannerPlatform.instance.stopScanning();
  }

  /// Dispose the scanner
  /// 
  /// Releases camera resources and cleans up.
  /// Should be called when scanner is no longer needed.
  Future<void> dispose() {
    return QuickqrScannerPlatform.instance.dispose();
  }

  /// Toggle flashlight (if available)
  /// 
  /// Returns:
  /// - isOn: current flashlight state
  /// - message: status message
  Future<Map<String, dynamic>> toggleFlashlight() {
    return QuickqrScannerPlatform.instance.toggleFlashlight();
  }

  /// Scan QR code from image file
  /// 
  /// [imagePath] - Path to the image file to scan
  /// 
  /// Returns [QRScanResult] if QR code found, null otherwise.
  /// Note: This method does not include image picker - you need to
  /// provide the image path yourself.
  Future<QRScanResult?> scanFromImage(String imagePath) {
    return QuickqrScannerPlatform.instance.scanFromImage(imagePath);
  }
}
