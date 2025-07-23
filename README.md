# QuickQR Scanner Plugin

[![pub package](https://img.shields.io/pub/v/quickqr_scanner_plugin.svg)](https://pub.dev/packages/quickqr_scanner_plugin)
[![Platform](https://img.shields.io/badge/platform-flutter-blue.svg)](https://flutter.dev)
[![iOS](https://img.shields.io/badge/iOS-12.0+-blue.svg)](https://developer.apple.com)
[![Android](https://img.shields.io/badge/Android-21+-green.svg)](https://developer.android.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B.svg)](https://flutter.dev)

Enterprise-grade QR code and barcode scanner plugin for Flutter with native Vision framework integration for iOS and ML Kit for Android. Designed for production apps requiring high-performance, low-latency scanning with comprehensive error handling.

## 🌟 Features

- **Native Performance**: Vision framework (iOS) + ML Kit (Android) for optimal speed
- **Real-time Scanning**: Live camera scanning with sub-second detection
- **Platform Views**: Native camera integration with Flutter UI overlay
- **Enterprise Error Handling**: Comprehensive status reporting and recovery
- **Image Processing**: Advanced quality analysis and enhancement
- **Multiple Formats**: QR Code, Code 128, Code 39, EAN-13, EAN-8, UPC-E
- **Permission Management**: Graceful camera permission handling
- **Resource Management**: Proper cleanup and memory management
- **Minimal Dependencies**: Lightweight with essential libraries only

## 📱 Supported Platforms

| Platform | Version | Framework | Performance |
|----------|---------|-----------|------------|
| iOS      | 12.0+   | Vision + AVFoundation | Hardware acceleration on supported devices |
| Android  | API 21+ | ML Kit + Camera2 API | Google ML optimization |

## 🚀 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  quickqr_scanner_plugin: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### iOS Configuration

Add camera permission to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes</string>
```

### Android Configuration

Add camera permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="true" />
```

## 💡 Quick Start

### Basic Usage

```dart
import 'package:quickqr_scanner_plugin/quickqr_scanner_plugin.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final _scanner = QuickqrScannerPlugin();
  StreamSubscription<QRScanResult>? _subscription;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    // Check device availability
    final availability = await _scanner.checkAvailability();
    if (!availability['isAvailable']) {
      print('QR scanning not supported on this device');
      return;
    }

    // Check permissions
    final permissions = await _scanner.checkPermissions();
    if (permissions['status'] != 'granted') {
      final requested = await _scanner.requestPermissions();
      if (!requested['granted']) {
        print('Camera permission required');
        return;
      }
    }

    // Initialize scanner
    await _scanner.initialize();
    
    // Listen for scan results
    _subscription = _scanner.onQRDetected.listen((result) {
      print('QR Code detected: ${result.content}');
      print('Format: ${result.format}');
      print('Confidence: ${result.confidence}');
    });

    // Start scanning
    await _scanner.startScanning();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scanner.dispose();
    super.dispose();
  }
}
```

### Image-based Scanning

```dart
// Scan QR code from image file
Future<void> scanFromImage(String imagePath) async {
  final scanner = QuickqrScannerPlugin();
  final result = await scanner.scanFromImage(imagePath);
  if (result != null) {
    print('QR Code: ${result.content}');
    print('Format: ${result.format}');
  } else {
    print('No QR code found in image');
  }
}
```

## 📖 API Reference

### QuickqrScannerPlugin

Main plugin class providing QR scanning functionality.

#### Properties

- `static instance` - Singleton instance
- `onQRDetected` - **Broadcast Stream<QRScanResult>** for real-time scan results
  - Emits QR/barcode detection events during active scanning
  - Supports multiple listeners with automatic error recovery
  - **⚠️ Remember to cancel subscriptions in `dispose()` to prevent memory leaks**

#### Methods

##### Device Information

```dart
Future<Map<String, dynamic>> checkAvailability()
```
Returns device scanning capabilities and supported formats.

```dart
Future<Map<String, dynamic>> checkPermissions()
```
Checks current camera permission status.

```dart
Future<Map<String, dynamic>> requestPermissions()
```
Requests camera permissions from user.

##### Scanner Control

```dart
Future<Map<String, dynamic>> initialize([QRScanConfig? config])
```
Initializes the scanner with optional configuration.

```dart
Future<void> startScanning()
```
Starts real-time QR code scanning.

```dart
Future<void> stopScanning()
```
Stops the scanning process.

```dart
Future<void> dispose()
```
Releases all resources and cleans up.

##### Additional Features

```dart
Future<Map<String, dynamic>> toggleFlashlight()
```
Toggles device flashlight (if available).

```dart
Future<QRScanResult?> scanFromImage(String imagePath)
```
Scans QR code from image file.

### Data Models

#### QRScanResult

```dart
class QRScanResult {
  final String content;     // QR code content
  final String format;      // Barcode format (qr, code128, etc.)
  final int timestamp;      // Detection timestamp (milliseconds)
  final double confidence;  // Detection confidence (0.0-1.0)
}
```

## 📱 Example App

A comprehensive example app is included in the `example/` directory demonstrating:

- Device capability detection
- Permission handling
- Real-time scanning with visual feedback
- Image-based scanning
- Error handling and recovery
- Scan result management
- Flashlight control

To run the example:

```bash
cd example
flutter run
```

## 🛠 Performance Notes

### iOS (VisionKit)
- **High Performance**: Native system integration
- **Low Battery Usage**: Optimized Apple Vision framework
- **System UI**: Consistent with iOS design patterns
- **Neural Engine**: Hardware acceleration on supported devices

### Android (ML Kit)
- **Google ML**: Powered by Google's machine learning
- **On-device Processing**: No internet connection required
- **Broad Compatibility**: Works on API level 21+
- **Efficient Detection**: Optimized for mobile devices

## 🚨 Troubleshooting

### Common Issues

**"Camera permission denied"**
- Ensure camera permission is added to platform manifests
- Check that user has granted permission in device settings
- Use `checkPermissions()` and `requestPermissions()` methods

**"Scanner not initialized"**
- Call `initialize()` before starting scanning
- Ensure initialization completes successfully before calling other methods
- Check device compatibility with `checkAvailability()`

**"No camera available"**
- Verify device has camera hardware
- Check that camera isn't being used by another app
- Try restarting the app or device

### Debug Mode

Enable detailed logging in debug builds:

```dart
// Add to main.dart for debugging
void main() {
  if (kDebugMode) {
    print('QuickQR Scanner Plugin Debug Mode Enabled');
  }
  runApp(MyApp());
}
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to get started.

## 📞 Support

- **Documentation**: [API Reference](API_REFERENCE.md)
- **Examples**: [More Examples](EXAMPLES.md)
- **Issues**: [GitHub Issues](https://github.com/ifapmzadu6/quickqr_scanner_plugin/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ifapmzadu6/quickqr_scanner_plugin/discussions)

---

Made with ❤️ for the Flutter community
