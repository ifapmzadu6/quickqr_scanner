# QuickQR Scanner Pro Example

A comprehensive example app demonstrating how to use the QuickQR Scanner Pro plugin.

## 🌟 Features Demonstrated

This example app showcases all the plugin's capabilities:

- **Real-time QR scanning** with live camera preview
- **Device capability detection** and compatibility checking
- **Permission management** with user-friendly dialogs
- **Image-based scanning** from file paths
- **Error handling** and recovery mechanisms
- **Scan result management** with history and copying
- **Flashlight control** for low-light conditions
- **Performance optimization** with proper lifecycle management

## 📱 Screenshots

The example app includes:

- **Status Dashboard**: Shows device info, permissions, and scanner status
- **Real-time Scanning**: Live camera scanning with visual feedback
- **Scan History**: List of recent scan results with timestamps
- **Error Handling**: Clear error messages and recovery suggestions

## 🚀 Running the Example

### Prerequisites

- Flutter 3.16.0 or higher
- iOS 12.0+ or Android API 21+
- Physical device with camera (camera not available in simulators)

### Setup

1. **Navigate to example directory**:
   ```bash
   cd example
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on device**:
   ```bash
   flutter run
   ```

### Platform Configuration

The example is already configured with necessary permissions:

**iOS (`ios/Runner/Info.plist`)**:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes</string>
```

**Android (`android/app/src/main/AndroidManifest.xml`)**:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="true" />
```

## 📖 Code Overview

### Main Components

#### Device Capability Check
```dart
Future<void> _checkDeviceCapabilities() async {
  final availability = await scanner.checkAvailability();
  setState(() {
    _deviceInfo = availability;
    _status = availability['isAvailable'] == true 
      ? 'デバイス対応確認済み - 初期化してください' 
      : 'このデバイスはQRスキャンに対応していません';
  });
}
```

#### Permission Handling
```dart
Future<void> _initializeScanner() async {
  final permissions = await scanner.checkPermissions();
  if (permissions['status'] != 'granted') {
    setState(() {
      _status = '権限が必要です - 設定から許可してください';
    });
    return;
  }
  // Initialize scanner...
}
```

#### Real-time Scanning
```dart
_scanSubscription = _scanner.onQRDetected.listen(
  (result) {
    setState(() {
      _scanResults.insert(0, result);
      if (_scanResults.length > 10) {
        _scanResults = _scanResults.take(10).toList();
      }
    });
  },
);
```

#### Error Handling
```dart
try {
  await _scanner.startScanning();
  setState(() {
    _isScanning = true;
    _status = 'スキャン中 - QRコードをカメラに向けてください';
  });
} catch (e) {
  setState(() {
    _status = 'スキャン開始エラー: $e';
  });
}
```

## 🎯 Testing the Example

### What to Test

1. **Initial Setup**:
   - App launches without errors
   - Device compatibility is correctly detected
   - Camera permissions are properly requested

2. **Real-time Scanning**:
   - Camera preview appears (black screen indicates camera issues)
   - QR codes are detected and results appear in the list
   - Flashlight toggle works (if device supports it)

3. **User Interface**:
   - Status messages are clear and informative
   - Scan results show correct content, format, and timestamp
   - Copy functionality works when tapping result items

4. **Error Scenarios**:
   - Permission denial is handled gracefully
   - Camera unavailable scenarios show appropriate messages
   - App recovery after errors works correctly

### Sample QR Codes for Testing

You can test with these QR code types:
- **Text**: Simple text content
- **URLs**: Web links (https://example.com)
- **WiFi**: Network credentials
- **Contact**: vCard format
- **Email**: mailto: links

### Performance Testing

- **Memory Usage**: Check app doesn't accumulate excessive memory
- **Battery Impact**: Scanning should not drain battery rapidly
- **CPU Usage**: App should remain responsive during scanning

## 🐛 Troubleshooting

### Common Issues

**Black Camera Screen**:
- Check camera permissions are granted
- Ensure no other app is using the camera
- Restart the app or device

**Permission Dialog Not Appearing**:
- Permission may have been permanently denied
- Guide user to app settings manually

**Poor Scan Performance**:
- Ensure good lighting conditions
- Check if device supports camera autofocus
- Try different QR codes to isolate issues

**Build Errors**:
- Run `flutter clean` and `flutter pub get`
- Ensure Flutter version compatibility
- Check platform-specific setup in main README

### Debug Mode

The example includes debug logging that can be enabled:

```dart
void main() {
  if (kDebugMode) {
    print('QuickQR Scanner Pro Example - Debug Mode');
  }
  runApp(const MyApp());
}
```

## 📚 Learning Resources

After exploring this example, you can:

1. **Study the source code** in `lib/main.dart`
2. **Read the plugin documentation**: [../README.md](../README.md)
3. **Check API reference**: [../API_REFERENCE.md](../API_REFERENCE.md)
4. **View more examples**: [../EXAMPLES.md](../EXAMPLES.md)
5. **Get help**: [../TROUBLESHOOTING.md](../TROUBLESHOOTING.md)

## 🔗 Integration Guide

To integrate QuickQR Scanner Pro into your own app:

1. **Add dependency** to your `pubspec.yaml`
2. **Configure permissions** for your target platforms
3. **Copy relevant code patterns** from this example
4. **Adapt UI** to match your app's design
5. **Handle errors** appropriately for your use case

## 📞 Support

If you encounter issues with this example:

- Check the [troubleshooting guide](../TROUBLESHOOTING.md)
- Search [existing issues](https://github.com/quickqr/quickqr_scanner_pro/issues)
- Create a new issue with detailed reproduction steps

---

This example demonstrates production-ready patterns for integrating QR scanning into Flutter applications. Use it as a reference for building your own implementations.
