/// Base exception for scanner operations
abstract class ScannerException implements Exception {
  final String message;
  final String? code;
  
  const ScannerException({
    required this.message,
    this.code,
  });
  
  @override
  String toString() => 'ScannerException: $message (code: $code)';
}

/// Camera permission denied exception
class CameraPermissionException extends ScannerException {
  const CameraPermissionException({
    super.message = 'Camera permission denied',
    super.code = 'PERMISSION_DENIED',
  });
}

/// Camera not available exception
class CameraUnavailableException extends ScannerException {
  const CameraUnavailableException({
    super.message = 'Camera not available',
    super.code = 'CAMERA_UNAVAILABLE',
  });
}

/// Scanner initialization failed exception
class ScannerInitializationException extends ScannerException {
  const ScannerInitializationException({
    required String message,
    super.code = 'INITIALIZATION_FAILED',
  }) : super(message: message);
}

/// Scan operation failed exception
class ScanFailedException extends ScannerException {
  const ScanFailedException({
    super.message = 'Scan operation failed',
    super.code = 'SCAN_FAILED',
  });
}

/// Image processing failed exception
class ImageProcessingException extends ScannerException {
  const ImageProcessingException({
    super.message = 'Image processing failed',
    super.code = 'IMAGE_PROCESSING_FAILED',
  });
}

/// Unsupported platform exception
class UnsupportedPlatformException extends ScannerException {
  const UnsupportedPlatformException({
    super.message = 'Platform not supported',
    super.code = 'UNSUPPORTED_PLATFORM',
  });
}