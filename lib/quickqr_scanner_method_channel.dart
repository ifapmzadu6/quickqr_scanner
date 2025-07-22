import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'quickqr_scanner_platform_interface.dart';
import 'src/models/qr_scan_result.dart';
import 'src/models/qr_scan_config.dart';

/// An implementation of [QuickqrScannerPlatform] that uses method channels.
class MethodChannelQuickqrScanner extends QuickqrScannerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('quickqr_scanner');
  
  /// Event channel for receiving QR scan results
  @visibleForTesting  
  static const EventChannel eventChannel = EventChannel('quickqr_scanner/events');
  
  Stream<QRScanResult>? _scanStream;

  @override
  Stream<QRScanResult> get onQRDetected {
    _scanStream ??= eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map<Object?, Object?>) {
        return QRScanResult.fromMap(Map<String, dynamic>.from(event));
      }
      throw Exception('Invalid scan result format');
    });
    return _scanStream!;
  }

  @override
  Future<Map<String, dynamic>> checkAvailability() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('checkAvailability');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> checkPermissions() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('checkPermissions');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> requestPermissions() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('requestPermissions');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> initialize([QRScanConfig? config]) async {
    try {
      final arguments = config?.toMap() ?? const QRScanConfig().toMap();
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('initialize', arguments);
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<void> startScanning() async {
    try {
      await methodChannel.invokeMethod('startScanning');
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<void> stopScanning() async {
    try {
      await methodChannel.invokeMethod('stopScanning');
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await methodChannel.invokeMethod('dispose');
      _scanStream = null;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> toggleFlashlight() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('toggleFlashlight');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  @override
  Future<QRScanResult?> scanFromImage(String imagePath) async {
    try {
      // Verify file exists
      if (!await File(imagePath).exists()) {
        throw PlatformException(
          code: 'FILE_NOT_FOUND',
          message: 'Image file not found: $imagePath',
        );
      }
      
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'scanFromImage', 
        {'imagePath': imagePath}
      );
      
      if (result != null) {
        return QRScanResult.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    }
  }

  /// Handle platform exceptions
  Exception _handlePlatformException(PlatformException e) {
    return Exception('${e.code}: ${e.message}');
  }
}
