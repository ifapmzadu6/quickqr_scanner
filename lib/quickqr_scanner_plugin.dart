// High-performance QR scanner with Vision framework integration for iOS and ML Kit for Android
// 
// This plugin provides enterprise-grade QR code scanning with:
// - Real-time QR code scanning using device camera with native performance
// - Image-based QR code scanning from files without picker dependency
// - Vision framework integration for iOS (hardware acceleration on supported devices)
// - ML Kit integration for Android (Google ML optimization)
// - Platform Views for seamless Flutter integration
// - Comprehensive error handling and resource management
// 
// Usage:
// ```dart
// import 'package:quickqr_scanner_plugin/quickqr_scanner_plugin.dart';
// 
// // Initialize scanner
// final scanner = QuickqrScannerPlugin();
// await scanner.initialize();
// 
// // Listen to scan results
// scanner.onQRDetected.listen((result) {
//   print('QR Code: ${result.content}');
// });
// 
// // Start scanning
// await scanner.startScanning();
// 
// // Scan from image  
// final result = await scanner.scanFromImage('/path/to/image.jpg');
// ```

import 'dart:async';

import 'quickqr_scanner_platform_interface.dart';
import 'src/models/qr_scan_result.dart';
import 'src/models/qr_scan_config.dart';
import 'src/models/camera_control_config.dart';

export 'src/models/qr_scan_result.dart';
export 'src/models/qr_scan_config.dart';
export 'src/models/camera_control_config.dart';
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

  // MARK: - Camera Control APIs

  /// Set zoom level during scanning
  /// 
  /// [zoomLevel] - Zoom level (1.0 = no zoom, higher values = more zoom)
  /// 
  /// Returns:
  /// - success: whether zoom was applied
  /// - currentZoom: actual zoom level set
  /// - maxZoom: maximum supported zoom level
  Future<Map<String, dynamic>> setZoomLevel(double zoomLevel) {
    return QuickqrScannerPlatform.instance.setZoomLevel(zoomLevel);
  }

  /// Get current zoom capabilities
  /// 
  /// Returns:
  /// - currentZoom: current zoom level
  /// - minZoom: minimum zoom level
  /// - maxZoom: maximum zoom level
  /// - supportsOpticalZoom: whether optical zoom is supported
  Future<Map<String, dynamic>> getZoomCapabilities() {
    return QuickqrScannerPlatform.instance.getZoomCapabilities();
  }

  /// Set focus mode and point
  /// 
  /// [focusMode] - Auto, manual, infinity, or macro focus
  /// [focusPoint] - Focus point for manual focus (normalized coordinates)
  /// 
  /// Returns:
  /// - success: whether focus was set
  /// - focusMode: current focus mode
  /// - focusPoint: current focus point (if manual)
  Future<Map<String, dynamic>> setFocusMode(FocusMode focusMode, [FocusPoint? focusPoint]) {
    return QuickqrScannerPlatform.instance.setFocusMode(focusMode, focusPoint);
  }

  /// Enable or disable macro mode for close-up scanning
  /// 
  /// [enabled] - Whether to enable macro mode
  /// 
  /// Returns:
  /// - success: whether macro mode was set
  /// - enabled: current macro mode state
  /// - supported: whether macro mode is supported
  Future<Map<String, dynamic>> setMacroMode(bool enabled) {
    return QuickqrScannerPlatform.instance.setMacroMode(enabled);
  }

  /// Get current macro mode state
  /// 
  /// Returns:
  /// - enabled: current macro mode state
  /// - supported: whether macro mode is supported
  Future<Map<String, dynamic>> getMacroModeState() {
    return QuickqrScannerPlatform.instance.getMacroModeState();
  }

  /// Get current focus state
  /// 
  /// Returns:
  /// - focusMode: current focus mode
  /// - focusPoint: current focus point (if manual)
  /// - supportedModes: list of supported focus modes
  Future<Map<String, dynamic>> getFocusState() {
    return QuickqrScannerPlatform.instance.getFocusState();
  }

  /// Get current exposure state
  /// 
  /// Returns:
  /// - exposureMode: current exposure mode
  /// - exposureCompensation: current exposure compensation
  /// - supportedModes: list of supported exposure modes
  Future<Map<String, dynamic>> getExposureState() {
    return QuickqrScannerPlatform.instance.getExposureState();
  }

  /// Get current camera resolution state
  /// 
  /// Returns:
  /// - resolution: current resolution setting
  /// - actualSize: actual resolution size (width x height)
  /// - supported: list of supported resolutions
  Future<Map<String, dynamic>> getCameraResolutionState() {
    return QuickqrScannerPlatform.instance.getCameraResolutionState();
  }

  /// Get current image stabilization state
  /// 
  /// Returns:
  /// - enabled: current stabilization state
  /// - supported: whether stabilization is supported
  Future<Map<String, dynamic>> getImageStabilizationState() {
    return QuickqrScannerPlatform.instance.getImageStabilizationState();
  }

  /// Get current white balance state
  /// 
  /// Returns:
  /// - whiteBalanceMode: current white balance mode
  /// - supported: list of supported white balance modes
  Future<Map<String, dynamic>> getWhiteBalanceState() {
    return QuickqrScannerPlatform.instance.getWhiteBalanceState();
  }

  /// Get current frame rate state
  /// 
  /// Returns:
  /// - frameRate: current frame rate
  /// - supportedRanges: supported frame rate ranges
  Future<Map<String, dynamic>> getFrameRateState() {
    return QuickqrScannerPlatform.instance.getFrameRateState();
  }

  /// Get current HDR state
  /// 
  /// Returns:
  /// - enabled: current HDR state
  /// - supported: whether HDR is supported
  Future<Map<String, dynamic>> getHDRState() {
    return QuickqrScannerPlatform.instance.getHDRState();
  }

  /// Set exposure mode and compensation
  /// 
  /// [exposureMode] - Auto or manual exposure
  /// [exposureCompensation] - Exposure compensation (-2.0 to +2.0)
  /// 
  /// Returns:
  /// - success: whether exposure was set
  /// - exposureMode: current exposure mode
  /// - exposureCompensation: current exposure compensation
  Future<Map<String, dynamic>> setExposureMode(ExposureMode exposureMode, [double? exposureCompensation]) {
    return QuickqrScannerPlatform.instance.setExposureMode(exposureMode, exposureCompensation);
  }

  /// Set camera resolution preference
  /// 
  /// [resolution] - Low, medium, high, or ultra resolution
  /// 
  /// Returns:
  /// - success: whether resolution was set
  /// - resolution: current resolution setting
  /// - actualSize: actual resolution size (width x height)
  Future<Map<String, dynamic>> setCameraResolution(CameraResolution resolution) {
    return QuickqrScannerPlatform.instance.setCameraResolution(resolution);
  }

  /// Switch between front and back camera
  /// 
  /// [position] - Front or back camera
  /// 
  /// Returns:
  /// - success: whether camera was switched
  /// - position: current camera position
  /// - available: list of available camera positions
  Future<Map<String, dynamic>> switchCamera(CameraPosition position) {
    return QuickqrScannerPlatform.instance.switchCamera(position);
  }

  /// Enable or disable image stabilization
  /// 
  /// [enabled] - Whether to enable stabilization
  /// 
  /// Returns:
  /// - success: whether stabilization was set
  /// - enabled: current stabilization state
  /// - supported: whether stabilization is supported
  Future<Map<String, dynamic>> setImageStabilization(bool enabled) {
    return QuickqrScannerPlatform.instance.setImageStabilization(enabled);
  }

  /// Set white balance mode
  /// 
  /// [whiteBalanceMode] - Auto, daylight, cloudy, tungsten, or fluorescent
  /// 
  /// Returns:
  /// - success: whether white balance was set
  /// - whiteBalanceMode: current white balance mode
  /// - supported: list of supported white balance modes
  Future<Map<String, dynamic>> setWhiteBalanceMode(WhiteBalanceMode whiteBalanceMode) {
    return QuickqrScannerPlatform.instance.setWhiteBalanceMode(whiteBalanceMode);
  }

  /// Set preferred frame rate for scanning
  /// 
  /// [frameRate] - Preferred frame rate in fps
  /// 
  /// Returns:
  /// - success: whether frame rate was set
  /// - frameRate: current frame rate
  /// - supportedRanges: supported frame rate ranges
  Future<Map<String, dynamic>> setFrameRate(int frameRate) {
    return QuickqrScannerPlatform.instance.setFrameRate(frameRate);
  }

  /// Enable or disable HDR mode
  /// 
  /// [enabled] - Whether to enable HDR
  /// 
  /// Returns:
  /// - success: whether HDR was set
  /// - enabled: current HDR state
  /// - supported: whether HDR is supported
  Future<Map<String, dynamic>> setHDRMode(bool enabled) {
    return QuickqrScannerPlatform.instance.setHDRMode(enabled);
  }

  /// Get current camera capabilities and settings
  /// 
  /// Returns comprehensive information about camera capabilities:
  /// - zoom: zoom capabilities and current state
  /// - focus: focus modes and current state
  /// - exposure: exposure capabilities and current state
  /// - resolution: supported resolutions and current state
  /// - features: supported features (macro, stabilization, HDR, etc.)
  Future<Map<String, dynamic>> getCameraCapabilities() {
    return QuickqrScannerPlatform.instance.getCameraCapabilities();
  }

  /// Apply complete camera control configuration
  /// 
  /// [config] - Camera control configuration to apply
  /// 
  /// Returns:
  /// - success: whether all settings were applied
  /// - applied: map of which settings were successfully applied
  /// - warnings: list of warnings about settings that couldn't be applied
  Future<Map<String, dynamic>> applyCameraControlConfig(CameraControlConfig config) {
    return QuickqrScannerPlatform.instance.applyCameraControlConfig(config);
  }
}
