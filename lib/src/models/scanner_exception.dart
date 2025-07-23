/// Error codes for scanner operations
enum ScannerErrorCode {
  // Initialization errors
  initializationFailed('INITIALIZATION_FAILED'),
  alreadyInitialized('ALREADY_INITIALIZED'),
  
  // Permission errors
  permissionDenied('PERMISSION_DENIED'),
  permissionRestricted('PERMISSION_RESTRICTED'),
  permissionNotDetermined('PERMISSION_NOT_DETERMINED'),
  
  // Camera errors
  cameraNotAvailable('CAMERA_NOT_AVAILABLE'),
  cameraInUse('CAMERA_IN_USE'),
  cameraError('CAMERA_ERROR'),
  
  // Scanning errors
  scanningNotActive('SCANNING_NOT_ACTIVE'),
  scanningAlreadyActive('SCANNING_ALREADY_ACTIVE'),
  scanTimeout('SCAN_TIMEOUT'),
  
  // File errors
  fileNotFound('FILE_NOT_FOUND'),
  fileReadError('FILE_READ_ERROR'),
  invalidImageFormat('INVALID_IMAGE_FORMAT'),
  
  // Configuration errors
  invalidConfiguration('INVALID_CONFIGURATION'),
  unsupportedFormat('UNSUPPORTED_FORMAT'),
  
  // Platform errors
  platformError('PLATFORM_ERROR'),
  methodNotImplemented('METHOD_NOT_IMPLEMENTED'),
  internalError('INTERNAL_ERROR'),
  
  // Network errors (for future use)
  networkError('NETWORK_ERROR'),
  
  // General errors
  unknownError('UNKNOWN_ERROR');
  
  const ScannerErrorCode(this.code);
  final String code;
  
  static ScannerErrorCode fromString(String code) {
    return ScannerErrorCode.values.firstWhere(
      (errorCode) => errorCode.code == code,
      orElse: () => ScannerErrorCode.unknownError,
    );
  }
}

/// Exception thrown by scanner operations
/// 
/// Provides structured error information with error codes,
/// human-readable messages, and optional additional details.
class ScannerException implements Exception {
  /// Error code identifying the type of error
  final ScannerErrorCode errorCode;
  
  /// Human-readable error message
  final String message;
  
  /// Additional error details
  final Map<String, dynamic>? details;
  
  /// Platform-specific error information
  final String? platformMessage;
  
  /// Timestamp when the error occurred
  final DateTime timestamp;
  
  ScannerException(
    this.errorCode,
    this.message, {
    this.details,
    this.platformMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Create from platform exception
  factory ScannerException.fromPlatform(dynamic platformException) {
    if (platformException is Map) {
      final code = platformException['code'] as String? ?? 'UNKNOWN_ERROR';
      final message = platformException['message'] as String? ?? 'Unknown error occurred';
      final details = platformException['details'] as Map<String, dynamic>?;
      
      return ScannerException(
        ScannerErrorCode.fromString(code),
        message,
        details: details,
        platformMessage: message,
        timestamp: DateTime.now(),
      );
    }
    
    return ScannerException(
      ScannerErrorCode.platformError,
      'Platform error occurred',
      platformMessage: platformException?.toString(),
      timestamp: DateTime.now(),
    );
  }
  
  /// Create a permission denied error
  factory ScannerException.permissionDenied() {
    return ScannerException(
      ScannerErrorCode.permissionDenied,
      'Camera permission denied. Please grant camera permission in device settings.',
      timestamp: DateTime.now(),
    );
  }
  
  /// Create a camera not available error
  factory ScannerException.cameraNotAvailable() {
    return ScannerException(
      ScannerErrorCode.cameraNotAvailable,
      'Camera not available. Please check if device has a camera and it\'s not in use by another app.',
      timestamp: DateTime.now(),
    );
  }
  
  /// Create a file not found error
  factory ScannerException.fileNotFound(String filePath) {
    return ScannerException(
      ScannerErrorCode.fileNotFound,
      'Image file not found: $filePath',
      details: {'filePath': filePath},
      timestamp: DateTime.now(),
    );
  }
  
  /// Create an initialization failed error
  factory ScannerException.initializationFailed(String reason) {
    return ScannerException(
      ScannerErrorCode.initializationFailed,
      'Scanner initialization failed: $reason',
      details: {'reason': reason},
      timestamp: DateTime.now(),
    );
  }
  
  /// Create an invalid configuration error
  factory ScannerException.invalidConfiguration(String reason) {
    return ScannerException(
      ScannerErrorCode.invalidConfiguration,
      'Invalid scanner configuration: $reason',
      details: {'reason': reason},
      timestamp: DateTime.now(),
    );
  }
  
  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'errorCode': errorCode.code,
      'message': message,
      'details': details,
      'platformMessage': platformMessage,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
  
  /// Check if this is a recoverable error
  bool get isRecoverable {
    switch (errorCode) {
      case ScannerErrorCode.permissionDenied:
      case ScannerErrorCode.permissionNotDetermined:
      case ScannerErrorCode.cameraInUse:
      case ScannerErrorCode.scanTimeout:
        return true;
      default:
        return false;
    }
  }
  
  /// Check if this error requires user action
  bool get requiresUserAction {
    switch (errorCode) {
      case ScannerErrorCode.permissionDenied:
      case ScannerErrorCode.permissionRestricted:
      case ScannerErrorCode.permissionNotDetermined:
        return true;
      default:
        return false;
    }
  }
  
  /// Get user-friendly error message
  String get userFriendlyMessage {
    switch (errorCode) {
      case ScannerErrorCode.permissionDenied:
        return 'Camera permission is required to scan QR codes. Please allow camera access in your device settings.';
      case ScannerErrorCode.cameraNotAvailable:
        return 'Camera is not available. Make sure no other app is using the camera.';
      case ScannerErrorCode.fileNotFound:
        return 'Selected image file could not be found.';
      case ScannerErrorCode.invalidImageFormat:
        return 'Selected file is not a valid image format.';
      case ScannerErrorCode.scanTimeout:
        return 'No QR code found. Try adjusting the camera angle or lighting.';
      case ScannerErrorCode.unsupportedFormat:
        return 'This barcode format is not supported.';
      default:
        return message;
    }
  }
  
  @override
  String toString() {
    final buffer = StringBuffer('ScannerException(${errorCode.code}): $message');
    
    if (platformMessage != null && platformMessage != message) {
      buffer.write(' [Platform: $platformMessage]');
    }
    
    if (details != null) {
      buffer.write(' - Details: $details');
    }
    
    buffer.write(' at ${timestamp.toIso8601String()}');
    
    return buffer.toString();
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScannerException &&
        other.errorCode == errorCode &&
        other.message == message &&
        other.platformMessage == platformMessage;
  }
  
  @override
  int get hashCode {
    return Object.hash(errorCode, message, platformMessage);
  }
}