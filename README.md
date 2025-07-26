# QuickQR Scanner Plugin

[![pub package](https://img.shields.io/pub/v/quickqr_scanner_plugin.svg)](https://pub.dev/packages/quickqr_scanner_plugin)
[![Platform](https://img.shields.io/badge/platform-flutter-blue.svg)](https://flutter.dev)
[![iOS](https://img.shields.io/badge/iOS-12.0+-blue.svg)](https://developer.apple.com)
[![Android](https://img.shields.io/badge/Android-21+-green.svg)](https://developer.android.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B.svg)](https://flutter.dev)

Enterprise-grade QR code and barcode scanner plugin for Flutter with native Vision framework integration for iOS and ML Kit for Android. Designed for production apps requiring high-performance, low-latency scanning with comprehensive error handling.

## 🌟 Features

### Core Scanning
- **Native Performance**: Vision framework (iOS) + ML Kit (Android) for optimal speed
- **Real-time Scanning**: Live camera scanning with sub-second detection
- **Platform Views**: Native camera integration with Flutter UI overlay
- **Multiple Formats**: QR Code, Code 128, Code 39, EAN-13, EAN-8, UPC-E
- **Image Scanning**: Scan QR codes from image files without picker dependency

### 📸 Advanced Camera Control (v1.1.0+)
- **Digital Zoom**: 1.0x - 10.0x zoom control with smooth adjustment
- **Macro Mode**: Close-up scanning for small QR codes
- **Focus Control**: Auto, manual, infinity, and macro focus modes with point-of-interest
- **Exposure Control**: Automatic and manual exposure with EV compensation
- **White Balance**: Auto, daylight, cloudy, tungsten, and fluorescent modes
- **Image Stabilization**: Hardware-based stabilization where available
- **HDR Mode**: High Dynamic Range for challenging lighting conditions
- **Frame Rate Control**: Adjustable frame rates (15-60fps) for performance
- **Camera Switching**: Front/back camera selection
- **Preset Configurations**: Macro, distant, low-light, and performance presets

### Enterprise Features
- **Enterprise Error Handling**: Comprehensive status reporting and recovery
- **Permission Management**: Graceful camera permission handling
- **Resource Management**: Proper cleanup and memory management
- **State Management**: Real-time access to all camera settings
- **Capability Detection**: Check device support for each feature
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
  quickqr_scanner_plugin: ^1.1.0
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

## 📸 Advanced Camera Control

### Basic Camera Control

```dart
import 'package:quickqr_scanner_plugin/quickqr_scanner_plugin.dart';

class AdvancedQRScanner extends StatefulWidget {
  @override
  _AdvancedQRScannerState createState() => _AdvancedQRScannerState();
}

class _AdvancedQRScannerState extends State<AdvancedQRScanner> {
  final _scanner = QuickqrScannerPlugin();
  double _currentZoom = 1.0;
  double _maxZoom = 1.0;
  bool _macroMode = false;

  @override
  void initState() {
    super.initState();
    _initializeWithCameraControl();
  }

  Future<void> _initializeWithCameraControl() async {
    // Initialize scanner
    await _scanner.initialize();
    
    // Get camera capabilities
    final capabilities = await _scanner.getCameraCapabilities();
    final zoomInfo = await _scanner.getZoomCapabilities();
    
    setState(() {
      _maxZoom = zoomInfo['maxZoom']?.toDouble() ?? 1.0;
    });
  }

  // Zoom control
  Future<void> _setZoom(double zoomLevel) async {
    final result = await _scanner.setZoomLevel(zoomLevel);
    if (result['success'] == true) {
      setState(() {
        _currentZoom = result['currentZoom']?.toDouble() ?? zoomLevel;
      });
    }
  }

  // Macro mode for close-up scanning
  Future<void> _toggleMacroMode() async {
    final result = await _scanner.setMacroMode(!_macroMode);
    if (result['success'] == true) {
      setState(() {
        _macroMode = result['enabled'] ?? !_macroMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Advanced QR Scanner')),
      body: Column(
        children: [
          // Zoom control
          if (_maxZoom > 1.0)
            Slider(
              value: _currentZoom,
              min: 1.0,
              max: _maxZoom,
              divisions: (_maxZoom * 10).round() - 10,
              label: '${_currentZoom.toStringAsFixed(1)}x',
              onChanged: _setZoom,
            ),
          
          // Macro mode toggle
          SwitchListTile(
            title: Text('Macro Mode'),
            subtitle: Text('For small QR codes'),
            value: _macroMode,
            onChanged: (_) => _toggleMacroMode(),
          ),
          
          // Camera preview would go here
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Text(
                  'Camera Preview',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Preset Configurations

```dart
// Macro configuration for close-up scanning
final macroConfig = CameraControlConfig.macro();
await scanner.applyCameraControlConfig(macroConfig);

// Distant configuration for far-range scanning
final distantConfig = CameraControlConfig.distant();
await scanner.applyCameraControlConfig(distantConfig);

// Low light configuration
final lowLightConfig = CameraControlConfig.lowLight();
await scanner.applyCameraControlConfig(lowLightConfig);

// Performance optimized configuration
final performanceConfig = CameraControlConfig.performance();
await scanner.applyCameraControlConfig(performanceConfig);
```

### Manual Camera Control

```dart
// Set specific focus mode with point of interest
await scanner.setFocusMode(FocusMode.manual, FocusPoint(0.5, 0.5));

// Adjust exposure compensation
await scanner.setExposureMode(ExposureMode.manual, -0.5);

// Set white balance for specific lighting
await scanner.setWhiteBalanceMode(WhiteBalanceMode.tungsten);

// Enable image stabilization
await scanner.setImageStabilization(true);

// Set frame rate for performance optimization
await scanner.setFrameRate(30);

// Enable HDR mode for challenging lighting
await scanner.setHDRMode(true);
```

### State Monitoring

```dart
// Get current camera state
final zoomState = await scanner.getZoomCapabilities();
final focusState = await scanner.getFocusState();
final exposureState = await scanner.getExposureState();
final macroState = await scanner.getMacroModeState();

print('Current zoom: ${zoomState['currentZoom']}x');
print('Focus mode: ${focusState['focusMode']}');
print('Macro enabled: ${macroState['enabled']}');

// Get comprehensive camera capabilities
final capabilities = await scanner.getCameraCapabilities();
final features = capabilities['features'] as Map<String, dynamic>;

if (features['macroMode'] == true) {
  print('Macro mode supported');
}
if (features['stabilization'] == true) {
  print('Image stabilization available');
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

##### Camera Control (v1.1.0+)

```dart
Future<Map<String, dynamic>> setZoomLevel(double zoomLevel)
```
Sets digital zoom level (1.0x - 10.0x).

```dart
Future<Map<String, dynamic>> getZoomCapabilities()
```
Gets current zoom level and capabilities.

```dart
Future<Map<String, dynamic>> setMacroMode(bool enabled)
```
Enables/disables macro mode for close-up scanning.

```dart
Future<Map<String, dynamic>> setFocusMode(FocusMode focusMode, [FocusPoint? focusPoint])
```
Sets focus mode with optional point of interest.

```dart
Future<Map<String, dynamic>> setExposureMode(ExposureMode exposureMode, [double? exposureCompensation])
```
Sets exposure mode with optional EV compensation.

```dart
Future<Map<String, dynamic>> setCameraResolution(CameraResolution resolution)
```
Sets camera resolution preference.

```dart
Future<Map<String, dynamic>> switchCamera(CameraPosition position)
```
Switches between front and back camera.

```dart
Future<Map<String, dynamic>> setImageStabilization(bool enabled)
```
Enables/disables image stabilization.

```dart
Future<Map<String, dynamic>> setWhiteBalanceMode(WhiteBalanceMode whiteBalanceMode)
```
Sets white balance mode.

```dart
Future<Map<String, dynamic>> setFrameRate(int frameRate)
```
Sets preferred frame rate.

```dart
Future<Map<String, dynamic>> setHDRMode(bool enabled)
```
Enables/disables HDR mode.

```dart
Future<Map<String, dynamic>> getCameraCapabilities()
```
Gets comprehensive camera capabilities.

```dart
Future<Map<String, dynamic>> applyCameraControlConfig(CameraControlConfig config)
```
Applies complete camera configuration.

##### Camera State (v1.1.0+)

```dart
Future<Map<String, dynamic>> getMacroModeState()
```
Gets current macro mode state.

```dart
Future<Map<String, dynamic>> getFocusState()
```
Gets current focus mode and settings.

```dart
Future<Map<String, dynamic>> getExposureState()
```
Gets current exposure settings.

```dart
Future<Map<String, dynamic>> getCameraResolutionState()
```
Gets current resolution settings.

```dart
Future<Map<String, dynamic>> getImageStabilizationState()
```
Gets current stabilization state.

```dart
Future<Map<String, dynamic>> getWhiteBalanceState()
```
Gets current white balance settings.

```dart
Future<Map<String, dynamic>> getFrameRateState()
```
Gets current frame rate settings.

```dart
Future<Map<String, dynamic>> getHDRState()
```
Gets current HDR state.

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

#### CameraControlConfig (v1.1.0+)

```dart
class CameraControlConfig {
  final double zoomLevel;              // Digital zoom level (1.0-10.0)
  final bool enableMacroMode;          // Enable macro mode
  final FocusMode focusMode;           // Focus mode setting
  final FocusPoint? focusPoint;        // Manual focus point
  final ExposureMode exposureMode;     // Exposure mode
  final double? exposureCompensation;  // EV compensation
  final CameraResolution resolution;   // Resolution preference
  final CameraPosition position;       // Camera position
  final bool enableStabilization;      // Image stabilization
  final WhiteBalanceMode whiteBalance; // White balance mode
  final int? preferredFrameRate;       // Frame rate preference
  final bool enableHDR;                // HDR mode

  // Preset factory constructors
  factory CameraControlConfig.macro();       // Close-up scanning
  factory CameraControlConfig.distant();     // Far-range scanning
  factory CameraControlConfig.lowLight();    // Low light conditions
  factory CameraControlConfig.performance(); // Performance optimized
}
```

#### Enums

```dart
enum FocusMode { auto, manual, infinity, macro }
enum ExposureMode { auto, manual }
enum CameraResolution { low, medium, high, ultra }
enum CameraPosition { back, front }
enum WhiteBalanceMode { auto, daylight, cloudy, tungsten, fluorescent }

class FocusPoint {
  final double x; // Normalized coordinates (0.0-1.0)
  final double y; // Normalized coordinates (0.0-1.0)
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
