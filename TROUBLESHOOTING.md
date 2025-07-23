# Troubleshooting Guide

Common issues and solutions for QuickQR Scanner Plugin Flutter plugin.

## 📋 Table of Contents

- [Installation Issues](#installation-issues)
- [Permission Problems](#permission-problems)
- [Camera Issues](#camera-issues)
- [Scanning Problems](#scanning-problems)
- [Performance Issues](#performance-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Build and Compilation Errors](#build-and-compilation-errors)
- [Debug and Logging](#debug-and-logging)

## 🔧 Installation Issues

### Plugin Not Found

**Problem**: `Package quickqr_scanner_plugin was not found`

**Solutions**:
1. Check `pubspec.yaml` syntax:
   ```yaml
   dependencies:
     quickqr_scanner_plugin: ^1.0.0
   ```

2. Run dependency installation:
   ```bash
   flutter pub get
   ```

3. Clear Flutter cache:
   ```bash
   flutter clean
   flutter pub get
   ```

4. Check package name spelling and version availability on pub.dev

### Version Conflicts

**Problem**: `version solving failed` or dependency conflicts

**Solutions**:
1. Update Flutter SDK:
   ```bash
   flutter upgrade
   ```

2. Check Flutter version compatibility:
   ```bash
   flutter --version
   # Requires Flutter 3.16.0 or higher
   ```

3. Resolve dependency conflicts:
   ```bash
   flutter pub deps
   flutter pub upgrade --major-versions
   ```

4. Use dependency overrides if needed:
   ```yaml
   dependency_overrides:
     some_conflicting_package: ^1.0.0
   ```

## 🔐 Permission Problems

### Camera Permission Denied

**Problem**: `PERMISSION_DENIED` error when initializing scanner

**iOS Solutions**:
1. Add camera permission to `ios/Runner/Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app needs camera access to scan QR codes</string>
   ```

2. Check permission status:
   ```dart
   final permissions = await scanner.checkPermissions();
   print('Permission status: ${permissions['status']}');
   ```

3. Request permission explicitly:
   ```dart
   final result = await scanner.requestPermissions();
   if (!result['granted']) {
     // Guide user to settings
     _openAppSettings();
   }
   ```

**Android Solutions**:
1. Add camera permission to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-feature android:name="android.hardware.camera" android:required="true" />
   ```

2. For Android 6.0+ (API 23+), request runtime permissions:
   ```dart
   if (permissions['status'] == 'denied' && permissions['canRequest']) {
     final result = await scanner.requestPermissions();
     // Handle result
   }
   ```

### Permission Dialog Not Showing

**Problem**: Permission request doesn't show system dialog

**Solutions**:
1. Check if permission was previously denied permanently
2. Guide user to app settings:
   ```dart
   void _showPermissionDialog() {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('Camera Permission Required'),
         content: Text(
           'Please enable camera permission in app settings to use QR scanner.',
         ),
         actions: [
           TextButton(
             onPressed: () => openAppSettings(), // Use url_launcher
             child: Text('Open Settings'),
           ),
         ],
       ),
     );
   }
   ```

3. Clear app data/cache and try again

## 📷 Camera Issues

### Camera Not Available

**Problem**: `NO_CAMERA` error or camera initialization fails

**Solutions**:
1. Check device compatibility:
   ```dart
   final availability = await scanner.checkAvailability();
   if (!availability['isAvailable']) {
     print('Camera not available: ${availability['deviceInfo']}');
   }
   ```

2. Verify camera hardware:
   - Ensure device has a working camera
   - Check if camera is being used by another app
   - Restart the device

3. Test on different devices to isolate hardware issues

### Camera Initialization Timeout

**Problem**: Scanner initialization hangs or times out

**Solutions**:
1. Add timeout to initialization:
   ```dart
   Future<void> _initializeWithTimeout() async {
     try {
       await scanner.initialize().timeout(Duration(seconds: 10));
     } on TimeoutException {
       throw Exception('Camera initialization timed out');
     }
   }
   ```

2. Check for resource conflicts:
   - Close other camera-using apps
   - Restart the app
   - Reboot device

3. Handle initialization errors gracefully:
   ```dart
   Future<void> _initializeWithRetry() async {
     int attempts = 0;
     const maxAttempts = 3;
     
     while (attempts < maxAttempts) {
       try {
         await scanner.initialize();
         return; // Success
       } catch (e) {
         attempts++;
         if (attempts >= maxAttempts) rethrow;
         
         await Future.delayed(Duration(seconds: 2 * attempts));
       }
     }
   }
   ```

### Camera Preview Issues

**Problem**: Camera preview is black, rotated, or distorted

**Solutions**:
1. Check device orientation handling
2. Ensure proper lifecycle management:
   ```dart
   @override
   void didChangeAppLifecycleState(AppLifecycleState state) {
     switch (state) {
       case AppLifecycleState.paused:
         scanner.stopScanning();
         break;
       case AppLifecycleState.resumed:
         scanner.startScanning();
         break;
     }
   }
   ```

3. Restart camera session:
   ```dart
   Future<void> _restartCamera() async {
     await scanner.stopScanning();
     await Future.delayed(Duration(seconds: 1));
     await scanner.startScanning();
   }
   ```

## 🔍 Scanning Problems

### QR Code Not Detected

**Problem**: Scanner doesn't detect visible QR codes

**Solutions**:
1. **Lighting Conditions**:
   - Ensure adequate lighting
   - Use flashlight in low light:
     ```dart
     await scanner.toggleFlashlight();
     ```
   - Avoid strong backlighting

2. **Distance and Positioning**:
   - Move closer/farther from QR code
   - Ensure QR code fills significant portion of camera view
   - Keep device steady

3. **QR Code Quality**:
   - Check if QR code is damaged or distorted
   - Try scanning different QR codes
   - Ensure high contrast between code and background

4. **Scan Configuration**:
   ```dart
   final config = QRScanConfig(
     scanInterval: Duration(milliseconds: 500), // Faster scanning
     enabledFormats: ['qr'], // Focus on QR codes only
   );
   await scanner.initialize(config);
   ```

### Slow or Intermittent Detection

**Problem**: Scanner takes too long to detect or misses codes

**Solutions**:
1. **Optimize Scan Interval**:
   ```dart
   final config = QRScanConfig(
     scanInterval: Duration(milliseconds: 200), // Faster scanning
   );
   ```

2. **Check Device Performance**:
   - Close background apps
   - Check available memory
   - Test on different devices

3. **Reduce Processing Load**:
   ```dart
   final config = QRScanConfig(
     enabledFormats: ['qr'], // Scan only needed formats
     enableMultiScan: false, // Disable multi-detection
   );
   ```

### Wrong Format Detection

**Problem**: Scanner detects wrong barcode format

**Solutions**:
1. **Specify Target Formats**:
   ```dart
   final config = QRScanConfig(
     enabledFormats: ['qr'], // Only QR codes
   );
   ```

2. **Validate Results**:
   ```dart
   scanner.onQRDetected.listen((result) {
     if (result.format != 'qr') {
       return; // Ignore non-QR codes
     }
     // Process QR code
   });
   ```

### False Positive Detection

**Problem**: Scanner detects non-existent codes or wrong content

**Solutions**:
1. **Check Confidence Score**:
   ```dart
   scanner.onQRDetected.listen((result) {
     if (result.confidence < 0.8) {
       return; // Ignore low-confidence results
     }
     // Process high-confidence results
   });
   ```

2. **Implement Duplicate Filtering**:
   ```dart
   String? _lastScannedContent;
   DateTime? _lastScanTime;
   
   void _handleScanResult(QRScanResult result) {
     final now = DateTime.now();
     
     // Ignore duplicate scans within 2 seconds
     if (_lastScannedContent == result.content &&
         _lastScanTime != null &&
         now.difference(_lastScanTime!) < Duration(seconds: 2)) {
       return;
     }
     
     _lastScannedContent = result.content;
     _lastScanTime = now;
     
     // Process new scan
     _processScanResult(result);
   }
   ```

## ⚡ Performance Issues

### High CPU Usage

**Problem**: App uses too much CPU during scanning

**Solutions**:
1. **Optimize Scan Frequency**:
   ```dart
   final config = QRScanConfig(
     scanInterval: Duration(seconds: 1), // Reduce frequency
   );
   ```

2. **Pause Scanning When Not Needed**:
   ```dart
   @override
   void didChangeAppLifecycleState(AppLifecycleState state) {
     if (state == AppLifecycleState.paused) {
       scanner.stopScanning(); // Save CPU when app is backgrounded
     } else if (state == AppLifecycleState.resumed) {
       scanner.startScanning();
     }
   }
   ```

3. **Limit Enabled Formats**:
   ```dart
   final config = QRScanConfig(
     enabledFormats: ['qr'], // Only scan for needed formats
   );
   ```

### High Memory Usage

**Problem**: App consumes too much memory

**Solutions**:
1. **Proper Disposal**:
   ```dart
   @override
   void dispose() {
     scanner.dispose(); // Always dispose
     super.dispose();
   }
   ```

2. **Limit Result History**:
   ```dart
   List<QRScanResult> _results = [];
   static const int _maxResults = 50;
   
   void _addResult(QRScanResult result) {
     _results.insert(0, result);
     if (_results.length > _maxResults) {
       _results = _results.take(_maxResults).toList();
     }
   }
   ```

3. **Monitor Memory Usage**:
   ```dart
   void _checkMemoryUsage() {
     final info = ProcessInfo.maxRss; // On supported platforms
     print('Memory usage: ${info ~/ 1024}KB');
   }
   ```

### Battery Drain

**Problem**: Scanner drains battery quickly

**Solutions**:
1. **Smart Scanning Management**:
   ```dart
   Timer? _inactivityTimer;
   
   void _startInactivityTimer() {
     _inactivityTimer?.cancel();
     _inactivityTimer = Timer(Duration(minutes: 2), () {
       scanner.stopScanning(); // Auto-stop after inactivity
     });
   }
   
   void _onUserInteraction() {
     _startInactivityTimer(); // Reset timer on user activity
   }
   ```

2. **Reduce Frame Rate**:
   ```dart
   final config = QRScanConfig(
     scanInterval: Duration(seconds: 2), // Lower frame rate
   );
   ```

3. **Turn Off Flashlight**:
   ```dart
   // Only use flashlight when explicitly requested by user
   bool _flashlightEnabled = false;
   
   void _toggleFlashlight() async {
     if (_flashlightEnabled) {
       await scanner.toggleFlashlight(); // Turn off
       _flashlightEnabled = false;
     }
   }
   ```

## 📱 Platform-Specific Issues

### iOS Issues

#### VisionKit Not Available

**Problem**: `VisionKit not supported` on older iOS versions

**Solution**: Plugin requires iOS 12.0+. Update `ios/Podfile`:
```ruby
platform :ios, '12.0'
```

#### Camera Permission Dialog Customization

**Problem**: Default permission message not descriptive enough

**Solution**: Update `Info.plist` with detailed message:
```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to scan QR codes and barcodes for quick data entry and processing.</string>
```

#### Build Issues with Xcode

**Problem**: Build fails with Swift or Xcode errors

**Solutions**:
1. Update Xcode to latest version
2. Clean build folder: `Product → Clean Build Folder`
3. Update CocoaPods:
   ```bash
   cd ios
   pod install --repo-update
   ```

### Android Issues

#### ML Kit Download Issues

**Problem**: First scan fails due to ML Kit model download

**Solution**: Handle model download gracefully:
```dart
bool _isFirstScan = true;

void _handleScanResult(QRScanResult result) {
  if (_isFirstScan) {
    _isFirstScan = false;
    _showMessage('Scanner ready!');
  }
  // Process result
}
```

#### ProGuard/R8 Issues

**Problem**: Release build fails or scanner doesn't work in release mode

**Solution**: Add ProGuard rules in `android/app/proguard-rules.pro`:
```
-keep class com.google.mlkit.** { *; }
-keep class androidx.camera.** { *; }
```

#### Camera2 API Issues

**Problem**: Scanner fails on older Android devices

**Solution**: Handle API level differences:
```dart
final availability = await scanner.checkAvailability();
final deviceInfo = availability['deviceInfo'];
print('Android version: ${deviceInfo['systemVersion']}');

if (deviceInfo['systemVersion'].startsWith('5.')) {
  // Handle Android 5.x limitations
  _showLimitedFeatureWarning();
}
```

## 🏗 Build and Compilation Errors

### Flutter Build Errors

#### Missing Dependencies

**Problem**: Build fails with missing dependency errors

**Solutions**:
1. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter build
   ```

2. Check Flutter doctor:
   ```bash
   flutter doctor -v
   ```

3. Update Flutter and dependencies:
   ```bash
   flutter upgrade
   flutter pub upgrade
   ```

#### Platform Channel Errors

**Problem**: `MissingPluginException` or platform channel issues

**Solutions**:
1. Hot restart instead of hot reload after adding plugin
2. Rebuild app completely:
   ```bash
   flutter clean
   flutter run
   ```

3. Check plugin registration in platform files

### Native Build Errors

#### iOS Build Fails

**Problem**: Swift compilation errors or missing frameworks

**Solutions**:
1. Update iOS deployment target:
   ```ruby
   # ios/Podfile
   platform :ios, '12.0'
   ```

2. Clean and rebuild:
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   flutter run
   ```

#### Android Build Fails

**Problem**: Gradle build errors or compilation issues

**Solutions**:
1. Check Android SDK and build tools versions
2. Clean Gradle cache:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter run
   ```

3. Update Gradle and dependencies in `android/build.gradle`

## 🐛 Debug and Logging

### Enable Debug Logging

Add debug logging to track issues:

```dart
void main() {
  if (kDebugMode) {
    // Enable detailed logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }
  runApp(MyApp());
}
```

### Platform-Specific Debugging

#### iOS Debugging

1. **Xcode Console**: View native iOS logs in Xcode console
2. **Device Logs**: Use Console app to view device logs
3. **Instruments**: Use Instruments for performance profiling

#### Android Debugging

1. **Logcat**: Use `flutter logs` or Android Studio Logcat
2. **ADB Logs**: 
   ```bash
   adb logcat | grep -i "quickqr"
   ```

### Common Debug Patterns

```dart
class DebugQRScanner extends StatefulWidget {
  @override
  _DebugQRScannerState createState() => _DebugQRScannerState();
}

class _DebugQRScannerState extends State<DebugQRScanner> {
  final _scanner = QuickqrScannerPlugin();
  
  @override
  void initState() {
    super.initState();
    _initWithDebugLogging();
  }
  
  Future<void> _initWithDebugLogging() async {
    try {
      print('🔍 Starting scanner initialization...');
      
      // Check availability
      final availability = await _scanner.checkAvailability();
      print('📱 Device availability: $availability');
      
      // Check permissions
      final permissions = await _scanner.checkPermissions();
      print('🔐 Permissions: $permissions');
      
      // Initialize
      await _scanner.initialize();
      print('✅ Scanner initialized successfully');
      
      // Setup listener with debugging
      _scanner.onQRDetected.listen(
        (result) {
          print('🎯 QR detected: ${result.content}');
          print('📊 Confidence: ${result.confidence}');
          print('⏰ Timestamp: ${result.timestamp}');
        },
        onError: (error) {
          print('❌ Scan error: $error');
        },
      );
      
      await _scanner.startScanning();
      print('🚀 Scanning started');
      
    } catch (e, stackTrace) {
      print('💥 Initialization failed: $e');
      print('📋 Stack trace: $stackTrace');
    }
  }
}
```

## 📞 Getting Help

If you're still experiencing issues:

1. **Check Documentation**:
   - [README.md](README.md) - Basic setup and usage
   - [API_REFERENCE.md](API_REFERENCE.md) - Detailed API documentation
   - [EXAMPLES.md](EXAMPLES.md) - Code examples and patterns

2. **Search Existing Issues**:
   - [GitHub Issues](https://github.com/ifapmzadu6/quickqr_scanner_plugin/issues)
   - Check closed issues for solutions

3. **Create New Issue**:
   - Use the issue template
   - Include debug logs
   - Provide minimal reproduction code
   - Specify device and OS versions

4. **Community Support**:
   - [GitHub Discussions](https://github.com/ifapmzadu6/quickqr_scanner_plugin/discussions)
   - Stack Overflow with tag `quickqr-scanner-plugin`

5. **Professional Support**:
   - Email: quickqr.scanner.plugin@gmail.com
   - Include detailed error logs and device information

## 🔧 Self-Diagnostic Checklist

Before reporting issues, run through this checklist:

- [ ] Plugin version is up to date
- [ ] Flutter SDK is compatible (3.16.0+)
- [ ] Platform permissions are correctly configured
- [ ] Device has working camera hardware
- [ ] Camera permissions are granted
- [ ] No other apps are using the camera
- [ ] App has been hot restarted after plugin installation
- [ ] Build is clean (ran `flutter clean`)
- [ ] Issue reproduces on multiple devices/platforms
- [ ] Debug logs have been collected
- [ ] Minimal reproduction code is available

---

Most issues can be resolved by following this troubleshooting guide. For complex issues, don't hesitate to reach out to the community or support team.