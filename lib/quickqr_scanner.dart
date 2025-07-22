/// High-performance QR scanner with VisionKit integration
/// 
/// This plugin provides:
/// - Real-time QR code scanning using device camera
/// - Image-based QR code scanning from files  
/// - VisionKit integration for iOS (high performance)
/// - Comprehensive error handling
/// 
/// Usage:
/// ```dart
/// import 'package:quickqr_scanner/quickqr_scanner.dart';
/// 
/// // Initialize scanner
/// await QuickQRScanner.instance.initialize();
/// 
/// // Listen to scan results
/// QuickQRScanner.instance.onQRDetected.listen((result) {
///   print('QR Code: ${result.content}');
/// });
/// 
/// // Start scanning
/// await QuickQRScanner.instance.startScanning();
/// 
/// // Scan from image  
/// final result = await QuickQRScanner.instance.scanFromImage('/path/to/image.jpg');
/// ```

import 'dart:async';

import 'quickqr_scanner_platform_interface.dart';
import 'src/models/qr_scan_result.dart';
import 'src/models/qr_scan_config.dart';

export 'src/models/qr_scan_result.dart';
export 'src/models/qr_scan_config.dart';
export 'src/models/scanner_exception.dart';

/// The main plugin class for QR scanning functionality
class QuickQRScanner {
  /// The singleton instance
  static QuickQRScanner? _instance;
  
  /// Get the singleton instance
  static QuickQRScanner get instance {
    return _instance ??= QuickQRScanner._();
  }
  
  QuickQRScanner._();

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
