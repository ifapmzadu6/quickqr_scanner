import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'quickqr_scanner_platform_interface.dart';
import 'src/models/qr_scan_result.dart';
import 'src/models/qr_scan_config.dart';
import 'src/models/camera_control_config.dart';
import 'src/models/scanner_exception.dart';

/// An implementation of [QuickqrScannerPlatform] that uses method channels.
/// 
/// Handles communication between Flutter and native platform implementations
/// using method channels and event channels with comprehensive error handling.
class MethodChannelQuickqrScanner extends QuickqrScannerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('quickqr_scanner');
  
  /// Event channel for receiving QR scan results
  @visibleForTesting  
  static const EventChannel eventChannel = EventChannel('quickqr_scanner/events');
  
  Stream<QRScanResult>? _scanStream;
  StreamSubscription<QRScanResult>? _scanSubscription;

  @override
  Stream<QRScanResult> get onQRDetected {
    _scanStream ??= eventChannel.receiveBroadcastStream()
      .map((event) => _parseScanResult(event))
      .handleError(_handleStreamError);
    return _scanStream!;
  }
  
  /// Parse scan result from platform event
  QRScanResult _parseScanResult(dynamic event) {
    try {
      if (event is Map<Object?, Object?>) {
        return QRScanResult.fromMap(Map<String, dynamic>.from(event));
      }
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Invalid scan result format received from platform',
        details: {'eventType': event.runtimeType.toString()},
      );
    } catch (e) {
      if (e is ScannerException) rethrow;
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to parse scan result: $e',
        details: {'rawEvent': event.toString()},
      );
    }
  }
  
  /// Handle stream errors
  void _handleStreamError(dynamic error) {
    if (kDebugMode) {
      debugPrint('QuickQR Scanner: Stream error - $error');
    }
    // Could emit to error stream or handle differently
  }

  @override
  Future<Map<String, dynamic>> checkAvailability() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Checking device availability');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('checkAvailability');
      final availability = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Device availability result - $availability');
      }
      
      return availability;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'checkAvailability');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to check device availability: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> checkPermissions() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Checking camera permissions');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('checkPermissions');
      final permissions = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Permission check result - $permissions');
      }
      
      return permissions;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'checkPermissions');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to check permissions: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> requestPermissions() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Requesting camera permissions');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('requestPermissions');
      final permissions = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Permission request result - $permissions');
      }
      
      return permissions;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'requestPermissions');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to request permissions: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> initialize([QRScanConfig? config]) async {
    try {
      final configuration = config ?? const QRScanConfig();
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Initializing with config - $configuration');
      }
      
      // Validate configuration
      final warnings = configuration.validate();
      if (warnings.isNotEmpty && kDebugMode) {
        debugPrint('QuickQR Scanner: Configuration warnings - $warnings');
      }
      
      final arguments = configuration.toMap();
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('initialize', arguments);
      final initResult = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Initialization result - $initResult');
      }
      
      return initResult;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'initialize');
    } catch (e) {
      if (e is ScannerException) rethrow;
      throw ScannerException(
        ScannerErrorCode.initializationFailed,
        'Failed to initialize scanner: $e',
      );
    }
  }

  @override
  Future<void> startScanning() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Starting scanning');
      }
      
      await methodChannel.invokeMethod('startScanning');
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Scanning started successfully');
      }
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'startScanning');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to start scanning: $e',
      );
    }
  }

  @override
  Future<void> stopScanning() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Stopping scanning');
      }
      
      await methodChannel.invokeMethod('stopScanning');
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Scanning stopped successfully');
      }
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'stopScanning');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to stop scanning: $e',
      );
    }
  }

  @override
  Future<void> dispose() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Disposing scanner resources');
      }
      
      await methodChannel.invokeMethod('dispose');
      
      // Clean up local resources
      _scanSubscription?.cancel();
      _scanSubscription = null;
      _scanStream = null;
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Resources disposed successfully');
      }
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'dispose');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to dispose scanner: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> toggleFlashlight() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Toggling flashlight');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('toggleFlashlight');
      final flashlightState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Flashlight toggled - $flashlightState');
      }
      
      return flashlightState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'toggleFlashlight');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to toggle flashlight: $e',
      );
    }
  }

  @override
  Future<QRScanResult?> scanFromImage(String imagePath) async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Scanning image from path - $imagePath');
      }
      
      // Validate file path
      if (imagePath.isEmpty) {
        throw ScannerException.invalidConfiguration('Image path cannot be empty');
      }
      
      // Verify file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        throw ScannerException.fileNotFound(imagePath);
      }
      
      // Check file size (optional - could prevent memory issues)
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) { // 50MB limit
        throw ScannerException(
          ScannerErrorCode.fileReadError,
          'Image file too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Maximum size is 50MB.',
          details: {'filePath': imagePath, 'fileSize': fileSize},
        );
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'scanFromImage', 
        {'imagePath': imagePath}
      );
      
      if (result != null) {
        final scanResult = QRScanResult.fromMap(Map<String, dynamic>.from(result));
        
        if (kDebugMode) {
          debugPrint('QuickQR Scanner: Image scan result - ${scanResult.content}');
        }
        
        return scanResult;
      }
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: No QR code found in image');
      }
      
      return null;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'scanFromImage');
    } on ScannerException {
      rethrow;
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to scan image: $e',
        details: {'imagePath': imagePath},
      );
    }
  }

  // MARK: - Camera Control Methods

  @override
  Future<Map<String, dynamic>> setZoomLevel(double zoomLevel) async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Setting zoom level to ${zoomLevel}x');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'setZoomLevel', 
        {'zoomLevel': zoomLevel}
      );
      final zoomState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Zoom level set - $zoomState');
      }
      
      return zoomState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'setZoomLevel');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to set zoom level: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getZoomCapabilities() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Getting zoom capabilities');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getZoomCapabilities');
      final capabilities = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Zoom capabilities - $capabilities');
      }
      
      return capabilities;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'getZoomCapabilities');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to get zoom capabilities: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> setFocusMode(FocusMode focusMode, [FocusPoint? focusPoint]) async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Setting focus mode to ${focusMode.value}');
      }
      
      final arguments = {
        'focusMode': focusMode.value,
        if (focusPoint != null) 'focusPoint': focusPoint.toMap(),
      };
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'setFocusMode', 
        arguments
      );
      final focusState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Focus mode set - $focusState');
      }
      
      return focusState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'setFocusMode');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to set focus mode: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> setMacroMode(bool enabled) async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Setting macro mode to $enabled');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'setMacroMode', 
        {'enabled': enabled}
      );
      final macroState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Macro mode set - $macroState');
      }
      
      return macroState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'setMacroMode');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to set macro mode: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getMacroModeState() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Getting macro mode state');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getMacroModeState');
      final macroState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Macro mode state - $macroState');
      }
      
      return macroState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'getMacroModeState');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to get macro mode state: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> setExposureMode(ExposureMode exposureMode, [double? exposureCompensation]) async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Setting exposure mode to ${exposureMode.value}');
      }
      
      final arguments = {
        'exposureMode': exposureMode.value,
        if (exposureCompensation != null) 'exposureCompensation': exposureCompensation,
      };
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'setExposureMode', 
        arguments
      );
      final exposureState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Exposure mode set - $exposureState');
      }
      
      return exposureState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'setExposureMode');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to set exposure mode: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> setCameraResolution(CameraResolution resolution) async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Setting camera resolution to ${resolution.value}');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'setCameraResolution', 
        {'resolution': resolution.value}
      );
      final resolutionState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Camera resolution set - $resolutionState');
      }
      
      return resolutionState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'setCameraResolution');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to set camera resolution: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> switchCamera(CameraPosition position) async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Switching to ${position.value} camera');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'switchCamera', 
        {'position': position.value}
      );
      final cameraState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Camera switched - $cameraState');
      }
      
      return cameraState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'switchCamera');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to switch camera: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> setImageStabilization(bool enabled) async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Setting image stabilization to $enabled');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'setImageStabilization', 
        {'enabled': enabled}
      );
      final stabilizationState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Image stabilization set - $stabilizationState');
      }
      
      return stabilizationState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'setImageStabilization');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to set image stabilization: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> setWhiteBalanceMode(WhiteBalanceMode whiteBalanceMode) async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Setting white balance mode to ${whiteBalanceMode.value}');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'setWhiteBalanceMode', 
        {'whiteBalanceMode': whiteBalanceMode.value}
      );
      final whiteBalanceState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: White balance mode set - $whiteBalanceState');
      }
      
      return whiteBalanceState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'setWhiteBalanceMode');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to set white balance mode: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> setFrameRate(int frameRate) async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Setting frame rate to ${frameRate}fps');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'setFrameRate', 
        {'frameRate': frameRate}
      );
      final frameRateState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Frame rate set - $frameRateState');
      }
      
      return frameRateState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'setFrameRate');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to set frame rate: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> setHDRMode(bool enabled) async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Setting HDR mode to $enabled');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'setHDRMode', 
        {'enabled': enabled}
      );
      final hdrState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: HDR mode set - $hdrState');
      }
      
      return hdrState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'setHDRMode');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to set HDR mode: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getCameraCapabilities() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Getting camera capabilities');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getCameraCapabilities');
      final capabilities = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Camera capabilities - $capabilities');
      }
      
      return capabilities;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'getCameraCapabilities');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to get camera capabilities: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getFocusState() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Getting focus state');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getFocusState');
      final focusState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Focus state - $focusState');
      }
      
      return focusState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'getFocusState');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to get focus state: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getExposureState() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Getting exposure state');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getExposureState');
      final exposureState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Exposure state - $exposureState');
      }
      
      return exposureState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'getExposureState');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to get exposure state: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getCameraResolutionState() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Getting camera resolution state');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getCameraResolutionState');
      final resolutionState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Camera resolution state - $resolutionState');
      }
      
      return resolutionState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'getCameraResolutionState');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to get camera resolution state: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getImageStabilizationState() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Getting image stabilization state');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getImageStabilizationState');
      final stabilizationState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Image stabilization state - $stabilizationState');
      }
      
      return stabilizationState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'getImageStabilizationState');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to get image stabilization state: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getWhiteBalanceState() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Getting white balance state');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getWhiteBalanceState');
      final whiteBalanceState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: White balance state - $whiteBalanceState');
      }
      
      return whiteBalanceState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'getWhiteBalanceState');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to get white balance state: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getFrameRateState() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Getting frame rate state');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getFrameRateState');
      final frameRateState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Frame rate state - $frameRateState');
      }
      
      return frameRateState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'getFrameRateState');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to get frame rate state: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getHDRState() async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Getting HDR state');
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getHDRState');
      final hdrState = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: HDR state - $hdrState');
      }
      
      return hdrState;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'getHDRState');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to get HDR state: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> applyCameraControlConfig(CameraControlConfig config) async {
    try {
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Applying camera control config - $config');
      }
      
      // Validate configuration
      final warnings = config.validate();
      if (warnings.isNotEmpty && kDebugMode) {
        debugPrint('QuickQR Scanner: Camera control config warnings - $warnings');
      }
      
      final arguments = config.toMap();
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'applyCameraControlConfig', 
        arguments
      );
      final configResult = Map<String, dynamic>.from(result ?? {});
      
      if (kDebugMode) {
        debugPrint('QuickQR Scanner: Camera control config applied - $configResult');
      }
      
      return configResult;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e, 'applyCameraControlConfig');
    } catch (e) {
      throw ScannerException(
        ScannerErrorCode.internalError,
        'Failed to apply camera control config: $e',
      );
    }
  }

  /// Handle platform exceptions with enhanced error mapping
  ScannerException _handlePlatformException(PlatformException e, String methodName) {
    if (kDebugMode) {
      debugPrint('QuickQR Scanner: Platform exception in $methodName - ${e.code}: ${e.message}');
    }
    
    // Map common platform error codes to scanner error codes
    final errorCode = switch (e.code) {
      'PERMISSION_DENIED' => ScannerErrorCode.permissionDenied,
      'PERMISSION_RESTRICTED' => ScannerErrorCode.permissionRestricted,
      'PERMISSION_NOT_DETERMINED' => ScannerErrorCode.permissionNotDetermined,
      'CAMERA_NOT_AVAILABLE' => ScannerErrorCode.cameraNotAvailable,
      'CAMERA_IN_USE' => ScannerErrorCode.cameraInUse,
      'CAMERA_ERROR' => ScannerErrorCode.cameraError,
      'FILE_NOT_FOUND' => ScannerErrorCode.fileNotFound,
      'FILE_READ_ERROR' => ScannerErrorCode.fileReadError,
      'INVALID_IMAGE_FORMAT' => ScannerErrorCode.invalidImageFormat,
      'INITIALIZATION_FAILED' => ScannerErrorCode.initializationFailed,
      'ALREADY_INITIALIZED' => ScannerErrorCode.alreadyInitialized,
      'SCANNING_NOT_ACTIVE' => ScannerErrorCode.scanningNotActive,
      'SCANNING_ALREADY_ACTIVE' => ScannerErrorCode.scanningAlreadyActive,
      'SCAN_TIMEOUT' => ScannerErrorCode.scanTimeout,
      'UNSUPPORTED_FORMAT' => ScannerErrorCode.unsupportedFormat,
      'INVALID_CONFIGURATION' => ScannerErrorCode.invalidConfiguration,
      'ZOOM_NOT_SUPPORTED' => ScannerErrorCode.featureNotSupported,
      'FOCUS_NOT_SUPPORTED' => ScannerErrorCode.featureNotSupported,
      'MACRO_NOT_SUPPORTED' => ScannerErrorCode.featureNotSupported,
      'HDR_NOT_SUPPORTED' => ScannerErrorCode.featureNotSupported,
      'STABILIZATION_NOT_SUPPORTED' => ScannerErrorCode.featureNotSupported,
      _ => ScannerErrorCode.platformError,
    };
    
    return ScannerException(
      errorCode,
      e.message ?? 'Platform error occurred',
      details: e.details as Map<String, dynamic>?,
      platformMessage: e.message,
    );
  }
}
