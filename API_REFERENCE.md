# API Reference

Comprehensive API documentation for QuickQR Scanner Plugin Flutter plugin.

## Table of Contents

- [QuickqrScannerPlugin](#quickqrscanneriplugin)
- [Data Models](#data-models)
- [Platform Interfaces](#platform-interfaces)
- [Exceptions](#exceptions)
- [Usage Patterns](#usage-patterns)

## QuickqrScannerPlugin

Main plugin class providing QR and barcode scanning functionality.

### Constructor

```dart
QuickqrScannerPlugin()
```

Constructor for creating a new plugin instance.

### Properties

#### `static instance`

```dart
Constructor
```

Gets the singleton instance of the scanner.

**Returns:** `QuickqrScannerPlugin` - A new plugin instance

**Example:**
```dart
final scanner = QuickqrScannerPlugin();
```

#### `onQRDetected`

```dart
Stream<QRScanResult> get onQRDetected
```

**Broadcast Stream** for receiving QR scan results in real-time during active scanning sessions.

**Stream Behavior:**
- Emits `QRScanResult` objects when QR codes are successfully detected
- Only active during `startScanning()` → `stopScanning()` sessions
- Automatically filters duplicate detections within 1-second intervals
- Handles detection errors gracefully with detailed error information

**Returns:** `Stream<QRScanResult>` - Broadcast stream of scan results

**Key Features:**
- **Real-time detection**: Sub-second scanning performance
- **Error resilience**: Continues streaming even after individual scan errors
- **Memory efficient**: Automatic cleanup when scanner is disposed
- **Thread safe**: Safe to subscribe from multiple listeners

**Important Notes:**
⚠️ **Always cancel subscriptions** in `dispose()` to prevent memory leaks
⚠️ **Stream is only active** when scanner is initialized and scanning
⚠️ **Multiple listeners supported** - use broadcast stream pattern

**Basic Example:**
```dart
StreamSubscription<QRScanResult>? _subscription;

void _startListening() {
  _subscription = scanner.onQRDetected.listen(
    (result) {
      print('QR Content: ${result.content}');
      print('Format: ${result.format.value}');
      print('Confidence: ${result.confidence}');
      print('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(result.timestamp)}');
    },
    onError: (error) {
      print('Scan error: $error');
    },
    cancelOnError: false, // Continue listening after errors
  );
}

void _stopListening() {
  _subscription?.cancel();
  _subscription = null;
}
```

**Advanced Usage with Error Handling:**
```dart
scanner.onQRDetected.listen(
  (result) {
    // Handle successful scan
    handleQRCode(result);
  },
  onError: (error) {
    if (error is ScannerException) {
      switch (error.code) {
        case ScannerErrorCode.cameraError:
          showCameraErrorDialog();
          break;
        case ScannerErrorCode.scanTimeout:
          // Continue scanning, just a timeout
          break;
        default:
          print('Scanner error: ${error.message}');
      }
    }
  },
);
```

**Multiple Listeners Example:**
```dart
// UI updates
scanner.onQRDetected.listen((result) {
  setState(() {
    _lastResult = result;
  });
});

// Analytics tracking
scanner.onQRDetected.listen((result) {
  analytics.track('qr_scanned', {
    'format': result.format.value,
    'content_type': result.contentType,
  });
});

// Auto-action handling
scanner.onQRDetected
  .where((result) => result.format == BarcodeFormat.qr)
  .listen((result) {
    if (isUrl(result.content)) {
      launchUrl(result.content);
    }
  });
```

### Methods

#### Device Information Methods

##### `checkAvailability()`

```dart
Future<Map<String, dynamic>> checkAvailability()
```

Checks if the device supports QR scanning and returns capability information.

**Returns:** `Future<Map<String, dynamic>>` containing:
- `isSupported` (bool): Whether QR scanning is supported
- `isAvailable` (bool): Whether camera is available
- `supportedTypes` (List<String>): Supported barcode formats
- `deviceInfo` (Map<String, dynamic>): Device information
  - `model` (String): Device model
  - `systemVersion` (String): OS version
  - `framework` (String): Scanning framework used

**Example:**
```dart
final availability = await scanner.checkAvailability();
if (availability['isAvailable']) {
  print('Camera available');
  print('Supported formats: ${availability['supportedTypes']}');
}
```

##### `checkPermissions()`

```dart
Future<Map<String, dynamic>> checkPermissions()
```

Checks current camera permission status.

**Returns:** `Future<Map<String, dynamic>>` containing:
- `status` (String): Permission status ('granted', 'denied', 'notDetermined', 'restricted')
- `canRequest` (bool): Whether permission can be requested
- `hasCamera` (bool): Whether device has camera

**Example:**
```dart
final permissions = await scanner.checkPermissions();
switch (permissions['status']) {
  case 'granted':
    print('Camera permission granted');
    break;
  case 'denied':
    print('Camera permission denied');
    break;
  case 'notDetermined':
    print('Camera permission not yet requested');
    break;
}
```

##### `requestPermissions()`

```dart
Future<Map<String, dynamic>> requestPermissions()
```

Requests camera permissions from the user.

**Returns:** `Future<Map<String, dynamic>>` containing:
- `granted` (bool): Whether permission was granted
- `status` (String): Final permission status
- `alreadyDetermined` (bool): Whether permission was previously determined

**Example:**
```dart
final result = await scanner.requestPermissions();
if (result['granted']) {
  print('Permission granted');
} else {
  print('Permission denied');
}
```

#### Scanner Control Methods

##### `initialize()`

```dart
Future<Map<String, dynamic>> initialize([QRScanConfig? config])
```

Initializes the QR scanner with optional configuration.

**Parameters:**
- `config` (QRScanConfig?, optional): Scanner configuration

**Returns:** `Future<Map<String, dynamic>>` containing:
- `success` (bool): Whether initialization succeeded
- `framework` (String): Scanning framework used
- `hasCamera` (bool): Whether camera is available

**Throws:** 
- `Exception` if initialization fails

**Example:**
```dart
try {
  final config = QRScanConfig(
    enableMultiScan: false,
    scanInterval: Duration(seconds: 1),
  );
  final result = await scanner.initialize(config);
  print('Initialized with ${result['framework']}');
} catch (e) {
  print('Initialization failed: $e');
}
```

##### `startScanning()`

```dart
Future<void> startScanning()
```

Starts real-time QR code scanning. Results will be delivered via the `onQRDetected` stream.

**Throws:**
- `Exception` if scanner is not initialized
- `Exception` if scanning fails to start

**Example:**
```dart
try {
  await scanner.startScanning();
  print('Scanning started');
} catch (e) {
  print('Failed to start scanning: $e');
}
```

##### `stopScanning()`

```dart
Future<void> stopScanning()
```

Stops the scanning process.

**Example:**
```dart
await scanner.stopScanning();
print('Scanning stopped');
```

##### `dispose()`

```dart
Future<void> dispose()
```

Releases all resources and cleans up the scanner. Should be called when the scanner is no longer needed.

**Example:**
```dart
await scanner.dispose();
print('Scanner disposed');
```

#### Additional Features

##### `toggleFlashlight()`

```dart
Future<Map<String, dynamic>> toggleFlashlight()
```

Toggles the device flashlight if available.

**Returns:** `Future<Map<String, dynamic>>` containing:
- `isOn` (bool): Current flashlight state
- `message` (String): Status message

**Throws:**
- `Exception` if device doesn't have flashlight
- `Exception` if flashlight control fails

**Example:**
```dart
try {
  final result = await scanner.toggleFlashlight();
  print('Flashlight ${result['isOn'] ? 'on' : 'off'}');
} catch (e) {
  print('Flashlight error: $e');
}
```

##### `scanFromImage()`

```dart
Future<QRScanResult?> scanFromImage(String imagePath)
```

Scans QR code from an image file.

**Parameters:**
- `imagePath` (String): Absolute path to the image file

**Returns:** `Future<QRScanResult?>` - Scan result or null if no QR code found

**Throws:**
- `Exception` if image file not found
- `Exception` if image processing fails

**Example:**
```dart
try {
  final result = await scanner.scanFromImage('/path/to/image.jpg');
  if (result != null) {
    print('Found QR code: ${result.content}');
  } else {
    print('No QR code found in image');
  }
} catch (e) {
  print('Image scanning failed: $e');
}
```

## Data Models

### QRScanResult

Represents the result of a QR code scan.

```dart
class QRScanResult {
  final String content;
  final String format;
  final int timestamp;
  final double confidence;
}
```

#### Properties

- **content** (String): The decoded content of the QR code
- **format** (String): Barcode format ('qr', 'code128', 'code39', etc.)
- **timestamp** (int): Detection timestamp in milliseconds since epoch
- **confidence** (double): Detection confidence score (0.0-1.0)

#### Constructor

```dart
QRScanResult({
  required this.content,
  required this.format,
  required this.timestamp,
  required this.confidence,
});
```

#### Factory Constructor

```dart
factory QRScanResult.fromMap(Map<String, dynamic> map)
```

Creates a QRScanResult from a map (used internally for platform channel communication).

#### Methods

```dart
Map<String, dynamic> toMap()
String toString()
bool operator ==(Object other)
int get hashCode
```

### QRScanConfig

Configuration options for the QR scanner.

```dart
class QRScanConfig {
  final bool enableMultiScan;
  final Duration scanInterval;
  final List<String> enabledFormats;
}
```

#### Properties

- **enableMultiScan** (bool): Allow multiple simultaneous detections (default: false)
- **scanInterval** (Duration): Minimum time between detections (default: 1 second)
- **enabledFormats** (List<String>): Specific formats to scan for (default: all supported)

#### Constructor

```dart
const QRScanConfig({
  this.enableMultiScan = false,
  this.scanInterval = const Duration(seconds: 1),
  this.enabledFormats = const ['qr', 'code128', 'code39', 'ean13'],
});
```

#### Methods

```dart
Map<String, dynamic> toMap()
factory QRScanConfig.fromMap(Map<String, dynamic> map)
```

### ScannerException

Custom exception for scanner-related errors.

```dart
class ScannerException implements Exception {
  final String code;
  final String message;
  final dynamic details;
}
```

#### Properties

- **code** (String): Error code
- **message** (String): Human-readable error message
- **details** (dynamic): Additional error details

#### Common Error Codes

- `PERMISSION_DENIED`: Camera permission not granted
- `NOT_INITIALIZED`: Scanner not initialized
- `ALREADY_RUNNING`: Scanner already running
- `NO_CAMERA`: No camera available
- `INIT_ERROR`: Initialization failed
- `SCAN_ERROR`: Scanning operation failed
- `FILE_NOT_FOUND`: Image file not found
- `INVALID_IMAGE`: Invalid image format

## Platform Interfaces

### QuickqrScannerPlatform

Abstract base class for platform implementations.

```dart
abstract class QuickqrScannerPlatform extends PlatformInterface
```

#### Methods

All methods are abstract and implemented by platform-specific classes:

- `Stream<QRScanResult> get onQRDetected`
- `Future<Map<String, dynamic>> checkAvailability()`
- `Future<Map<String, dynamic>> checkPermissions()`
- `Future<Map<String, dynamic>> requestPermissions()`
- `Future<Map<String, dynamic>> initialize([QRScanConfig? config])`
- `Future<void> startScanning()`
- `Future<void> stopScanning()`
- `Future<void> dispose()`
- `Future<Map<String, dynamic>> toggleFlashlight()`
- `Future<QRScanResult?> scanFromImage(String imagePath)`

### MethodChannelQuickqrScanner

Default implementation using Flutter method channels.

```dart
class MethodChannelQuickqrScanner extends QuickqrScannerPlatform
```

#### Channel Names

- **Method Channel**: `quickqr_scanner_pro`
- **Event Channel**: `quickqr_scanner_pro/events`

## Usage Patterns

### Basic Scanner Setup

```dart
class ScannerService {
  final _scanner = QuickqrScannerPlugin();
  StreamSubscription<QRScanResult>? _subscription;

  Future<void> initialize() async {
    // Check availability
    final availability = await _scanner.checkAvailability();
    if (!availability['isAvailable']) {
      throw Exception('Scanning not supported');
    }

    // Handle permissions
    await _handlePermissions();

    // Initialize
    await _scanner.initialize();

    // Setup listener
    _subscription = _scanner.onQRDetected.listen(_onScanResult);
  }

  Future<void> _handlePermissions() async {
    final permissions = await _scanner.checkPermissions();
    if (permissions['status'] != 'granted') {
      final requested = await _scanner.requestPermissions();
      if (!requested['granted']) {
        throw Exception('Camera permission required');
      }
    }
  }

  void _onScanResult(QRScanResult result) {
    print('Scanned: ${result.content}');
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _scanner.dispose();
  }
}
```

### Error Handling Pattern

```dart
Future<void> safeScanning() async {
  try {
    await scanner.initialize();
    await scanner.startScanning();
  } on ScannerException catch (e) {
    switch (e.code) {
      case 'PERMISSION_DENIED':
        showPermissionDialog();
        break;
      case 'NO_CAMERA':
        showNoCameraError();
        break;
      default:
        showGenericError(e.message);
    }
  } catch (e) {
    showGenericError('Unexpected error: $e');
  }
}
```

### Image Batch Processing

```dart
Future<List<QRScanResult>> scanMultipleImages(List<String> imagePaths) async {
  final results = <QRScanResult>[];
  
  for (final path in imagePaths) {
    try {
      final result = await scanner.scanFromImage(path);
      if (result != null) {
        results.add(result);
      }
    } catch (e) {
      print('Failed to scan $path: $e');
    }
  }
  
  return results;
}
```

## Best Practices

### Resource Management

1. **Always dispose**: Call `dispose()` when done
2. **Cancel subscriptions**: Cancel stream subscriptions in dispose
3. **Handle errors**: Wrap scanner operations in try-catch blocks
4. **Check availability**: Verify device support before initialization

### Performance Optimization

1. **Use scan intervals**: Configure appropriate `scanInterval` to reduce CPU usage
2. **Limit formats**: Specify only needed formats in `enabledFormats`
3. **Stop when not needed**: Stop scanning when app goes to background
4. **Reuse instance**: Use the singleton instance, don't create multiple scanners

### User Experience

1. **Request permissions gracefully**: Explain why camera access is needed
2. **Provide feedback**: Show scanning status and results clearly
3. **Handle errors gracefully**: Provide clear error messages and recovery options
4. **Optimize UI**: Don't block UI thread during scanning operations

---

For more examples and advanced usage patterns, see [EXAMPLES.md](EXAMPLES.md).