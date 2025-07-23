import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'quickqr_scanner_platform_interface.dart';
import 'src/models/qr_scan_result.dart';
import 'src/models/qr_scan_config.dart';
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
