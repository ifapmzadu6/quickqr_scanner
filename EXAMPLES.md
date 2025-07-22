# Examples

Comprehensive examples for using QuickQR Scanner Pro in various scenarios.

## 📋 Table of Contents

- [Basic Usage](#basic-usage)
- [Advanced Scanning](#advanced-scanning)
- [Image Processing](#image-processing)
- [Error Handling](#error-handling)
- [UI Integration](#ui-integration)
- [Performance Optimization](#performance-optimization)
- [Production Patterns](#production-patterns)

## 🚀 Basic Usage

### Simple QR Scanner

```dart
import 'package:flutter/material.dart';
import 'package:quickqr_scanner_pro/quickqr_scanner_pro.dart';
import 'dart:async';

class SimpleQRScanner extends StatefulWidget {
  @override
  _SimpleQRScannerState createState() => _SimpleQRScannerState();
}

class _SimpleQRScannerState extends State<SimpleQRScanner> {
  final _scanner = QuickQRScannerPro.instance;
  StreamSubscription<QRScanResult>? _subscription;
  String _lastResult = 'No QR code scanned';

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  Future<void> _initScanner() async {
    await _scanner.initialize();
    
    _subscription = _scanner.onQRDetected.listen((result) {
      setState(() {
        _lastResult = result.content;
      });
    });
    
    await _scanner.startScanning();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Simple QR Scanner')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Last scanned:'),
            SizedBox(height: 10),
            Text(_lastResult, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
```

### Permission Handling

```dart
class PermissionAwareScanner extends StatefulWidget {
  @override
  _PermissionAwareScannerState createState() => _PermissionAwareScannerState();
}

class _PermissionAwareScannerState extends State<PermissionAwareScanner> {
  final _scanner = QuickQRScannerPro.instance;
  String _status = 'Checking permissions...';

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndInit();
  }

  Future<void> _checkPermissionsAndInit() async {
    try {
      // Check device capabilities
      final availability = await _scanner.checkAvailability();
      if (!availability['isAvailable']) {
        setState(() => _status = 'Camera not available on this device');
        return;
      }

      // Check permissions
      final permissions = await _scanner.checkPermissions();
      if (permissions['status'] == 'granted') {
        await _initializeScanner();
      } else if (permissions['canRequest']) {
        await _requestPermissions();
      } else {
        setState(() => _status = 'Camera permission denied. Please enable in settings.');
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _status = 'Requesting camera permission...');
    
    final result = await _scanner.requestPermissions();
    if (result['granted']) {
      await _initializeScanner();
    } else {
      setState(() => _status = 'Camera permission required for scanning');
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Camera Permission Required'),
        content: Text('This app needs camera access to scan QR codes. Please grant permission in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeScanner() async {
    setState(() => _status = 'Initializing scanner...');
    
    await _scanner.initialize();
    setState(() => _status = 'Ready to scan');
    await _scanner.startScanning();
  }

  // ... rest of widget implementation
}
```

## 🔧 Advanced Scanning

### Custom Configuration

```dart
class AdvancedQRScanner extends StatefulWidget {
  @override
  _AdvancedQRScannerState createState() => _AdvancedQRScannerState();
}

class _AdvancedQRScannerState extends State<AdvancedQRScanner> {
  final _scanner = QuickQRScannerPro.instance;
  StreamSubscription<QRScanResult>? _subscription;
  bool _multiScanEnabled = false;
  List<String> _enabledFormats = ['qr'];
  Duration _scanInterval = Duration(seconds: 1);

  Future<void> _initWithCustomConfig() async {
    final config = QRScanConfig(
      enableMultiScan: _multiScanEnabled,
      scanInterval: _scanInterval,
      enabledFormats: _enabledFormats,
    );

    await _scanner.initialize(config);
    
    _subscription = _scanner.onQRDetected.listen((result) {
      _handleScanResult(result);
    });
    
    await _scanner.startScanning();
  }

  void _handleScanResult(QRScanResult result) {
    print('Format: ${result.format}');
    print('Content: ${result.content}');
    print('Confidence: ${result.confidence}');
    print('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(result.timestamp)}');
  }

  Widget _buildConfigPanel() {
    return Column(
      children: [
        SwitchListTile(
          title: Text('Multi-scan Mode'),
          subtitle: Text('Allow multiple simultaneous detections'),
          value: _multiScanEnabled,
          onChanged: (value) {
            setState(() => _multiScanEnabled = value);
          },
        ),
        ListTile(
          title: Text('Scan Interval'),
          subtitle: Text('${_scanInterval.inMilliseconds}ms'),
          trailing: DropdownButton<Duration>(
            value: _scanInterval,
            items: [
              Duration(milliseconds: 500),
              Duration(seconds: 1),
              Duration(seconds: 2),
            ].map((duration) => DropdownMenuItem(
              value: duration,
              child: Text('${duration.inMilliseconds}ms'),
            )).toList(),
            onChanged: (value) {
              setState(() => _scanInterval = value!);
            },
          ),
        ),
        ExpansionTile(
          title: Text('Enabled Formats'),
          children: [
            'qr', 'code128', 'code39', 'ean13', 'ean8'
          ].map((format) => CheckboxListTile(
            title: Text(format.toUpperCase()),
            value: _enabledFormats.contains(format),
            onChanged: (checked) {
              setState(() {
                if (checked!) {
                  _enabledFormats.add(format);
                } else {
                  _enabledFormats.remove(format);
                }
              });
            },
          )).toList(),
        ),
      ],
    );
  }
}
```

### Multiple Format Detection

```dart
class MultiFormatScanner extends StatefulWidget {
  @override
  _MultiFormatScannerState createState() => _MultiFormatScannerState();
}

class _MultiFormatScannerState extends State<MultiFormatScanner> {
  final _scanner = QuickQRScannerPro.instance;
  Map<String, List<QRScanResult>> _resultsByFormat = {};

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  Future<void> _initScanner() async {
    final config = QRScanConfig(
      enabledFormats: ['qr', 'code128', 'code39', 'ean13', 'ean8'],
      scanInterval: Duration(milliseconds: 500),
    );

    await _scanner.initialize(config);
    
    _scanner.onQRDetected.listen((result) {
      setState(() {
        _resultsByFormat.putIfAbsent(result.format, () => []);
        _resultsByFormat[result.format]!.add(result);
      });
    });
    
    await _scanner.startScanning();
  }

  Widget _buildFormatResults(String format, List<QRScanResult> results) {
    return ExpansionTile(
      title: Text('${format.toUpperCase()} (${results.length})'),
      children: results.map((result) => ListTile(
        title: Text(result.content),
        subtitle: Text('Confidence: ${result.confidence.toStringAsFixed(2)}'),
        trailing: Text(DateTime.fromMillisecondsSinceEpoch(result.timestamp)
            .toString().substring(11, 19)),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Multi-Format Scanner'),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _resultsByFormat.clear();
              });
            },
          ),
        ],
      ),
      body: ListView(
        children: _resultsByFormat.entries.map((entry) => 
          _buildFormatResults(entry.key, entry.value)
        ).toList(),
      ),
    );
  }
}
```

## 🖼 Image Processing

### Batch Image Scanning

```dart
class BatchImageScanner extends StatefulWidget {
  @override
  _BatchImageScannerState createState() => _BatchImageScannerState();
}

class _BatchImageScannerState extends State<BatchImageScanner> {
  final _scanner = QuickQRScannerPro.instance;
  List<String> _imagePaths = [];
  Map<String, QRScanResult?> _results = {};
  bool _processing = false;

  Future<void> _scanImages() async {
    setState(() {
      _processing = true;
      _results.clear();
    });

    for (final imagePath in _imagePaths) {
      try {
        final result = await _scanner.scanFromImage(imagePath);
        _results[imagePath] = result;
      } catch (e) {
        print('Error scanning $imagePath: $e');
        _results[imagePath] = null;
      }
      
      setState(() {}); // Update UI for each result
    }

    setState(() => _processing = false);
  }

  Future<void> _scanImagesParallel() async {
    setState(() {
      _processing = true;
      _results.clear();
    });

    // Scan multiple images concurrently (be careful with resource usage)
    final futures = _imagePaths.map((imagePath) async {
      try {
        return MapEntry(imagePath, await _scanner.scanFromImage(imagePath));
      } catch (e) {
        print('Error scanning $imagePath: $e');
        return MapEntry(imagePath, null);
      }
    });

    final results = await Future.wait(futures);
    
    setState(() {
      _results = Map.fromEntries(results);
      _processing = false;
    });
  }

  Widget _buildResultsList() {
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final entry = _results.entries.elementAt(index);
        final imagePath = entry.key;
        final result = entry.value;
        
        return Card(
          child: ListTile(
            leading: Image.file(
              File(imagePath),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(result?.content ?? 'No QR code found'),
            subtitle: Text(path.basename(imagePath)),
            trailing: result != null 
              ? Icon(Icons.check_circle, color: Colors.green)
              : Icon(Icons.error, color: Colors.red),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Batch Image Scanner'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_photo_alternate),
            onPressed: _pickImages,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_processing) LinearProgressIndicator(),
          ElevatedButton(
            onPressed: _imagePaths.isNotEmpty && !_processing ? _scanImages : null,
            child: Text('Scan ${_imagePaths.length} Images'),
          ),
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }
}
```

### Image Quality Analysis

```dart
class QualityAwareImageScanner extends StatefulWidget {
  @override
  _QualityAwareImageScannerState createState() => _QualityAwareImageScannerState();
}

class _QualityAwareImageScannerState extends State<QualityAwareImageScanner> {
  final _scanner = QuickQRScannerPro.instance;

  Future<void> _scanWithQualityCheck(String imagePath) async {
    // First check image properties
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final image = await decodeImageFromList(bytes);
    
    // Check resolution
    if (image.width < 100 || image.height < 100) {
      _showQualityWarning('Image resolution too low (${image.width}x${image.height})');
      return;
    }
    
    // Check file size (very basic quality indicator)
    final sizeKB = bytes.length / 1024;
    if (sizeKB < 10) {
      _showQualityWarning('Image file size very small (${sizeKB.toStringAsFixed(1)}KB)');
    }

    try {
      final result = await _scanner.scanFromImage(imagePath);
      
      if (result != null) {
        _handleScanSuccess(result);
      } else {
        _showScanFailure('No QR code detected. Try improving image quality.');
      }
    } catch (e) {
      _showScanFailure('Scan failed: $e');
    }
  }

  void _showQualityWarning(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Image Quality Warning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 48),
            SizedBox(height: 16),
            Text(message),
            SizedBox(height: 16),
            Text('For best results:'),
            Text('• Use good lighting'),
            Text('• Hold camera steady'),
            Text('• Ensure QR code is clearly visible'),
            Text('• Avoid blur and shadows'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleScanSuccess(QRScanResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Content: ${result.content}'),
            Text('Format: ${result.format}'),
            Text('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result.content));
              Navigator.pop(context);
            },
            child: Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showScanFailure(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'HELP',
          textColor: Colors.white,
          onPressed: _showScanningTips,
        ),
      ),
    );
  }

  void _showScanningTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scanning Tips'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For better scanning results:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('📸 Good lighting is essential'),
            Text('🎯 Keep QR code centered and fully visible'),
            Text('📏 Maintain appropriate distance'),
            Text('🚫 Avoid reflections and shadows'),
            Text('📱 Hold device steady'),
            Text('🔍 Ensure QR code is not damaged'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

## 🛡 Error Handling

### Comprehensive Error Management

```dart
class RobustQRScanner extends StatefulWidget {
  @override
  _RobustQRScannerState createState() => _RobustQRScannerState();
}

class _RobustQRScannerState extends State<RobustQRScanner> 
    with WidgetsBindingObserver {
  final _scanner = QuickQRScannerPro.instance;
  StreamSubscription<QRScanResult>? _subscription;
  String _status = 'Initializing...';
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWithRetry();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _scanner.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        _pauseScanning();
        break;
      case AppLifecycleState.resumed:
        _resumeScanning();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _stopScanning();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _initializeWithRetry() async {
    try {
      await _initializeScanner();
      _retryCount = 0; // Reset retry count on success
    } catch (e) {
      if (_retryCount < _maxRetries) {
        _retryCount++;
        setState(() => _status = 'Initialization failed. Retrying... ($_retryCount/$_maxRetries)');
        
        await Future.delayed(Duration(seconds: 2 * _retryCount)); // Exponential backoff
        await _initializeWithRetry();
      } else {
        _handleFatalError('Failed to initialize after $_maxRetries attempts: $e');
      }
    }
  }

  Future<void> _initializeScanner() async {
    setState(() => _status = 'Checking device compatibility...');
    
    // Check availability
    final availability = await _scanner.checkAvailability();
    if (!availability['isAvailable']) {
      throw Exception('Camera not available');
    }

    setState(() => _status = 'Checking permissions...');
    
    // Handle permissions
    final permissions = await _scanner.checkPermissions();
    if (permissions['status'] != 'granted') {
      final requested = await _scanner.requestPermissions();
      if (!requested['granted']) {
        throw Exception('Camera permission denied');
      }
    }

    setState(() => _status = 'Initializing scanner...');
    
    // Initialize scanner
    await _scanner.initialize();
    
    // Setup error handling for scan stream
    _subscription = _scanner.onQRDetected.listen(
      _handleScanResult,
      onError: _handleScanError,
    );
    
    setState(() => _status = 'Starting camera...');
    
    // Start scanning
    await _scanner.startScanning();
    
    setState(() => _status = 'Ready - Point camera at QR code');
  }

  void _handleScanResult(QRScanResult result) {
    setState(() => _status = 'QR code detected!');
    
    // Show result with automatic dismiss
    _showScanResult(result);
    
    // Auto-resume scanning after delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _status = 'Ready - Point camera at QR code');
      }
    });
  }

  void _handleScanError(dynamic error) {
    print('Scan error: $error');
    setState(() => _status = 'Scanning error occurred');
    
    // Try to recover
    _recoverFromScanError();
  }

  Future<void> _recoverFromScanError() async {
    try {
      setState(() => _status = 'Recovering...');
      
      await _scanner.stopScanning();
      await Future.delayed(Duration(seconds: 1));
      await _scanner.startScanning();
      
      setState(() => _status = 'Ready - Point camera at QR code');
    } catch (e) {
      _handleFatalError('Failed to recover from scan error: $e');
    }
  }

  void _handleFatalError(String error) {
    setState(() => _status = 'Fatal error occurred');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Scanner Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(error),
            SizedBox(height: 16),
            Text('Please try the following:'),
            Text('• Restart the app'),
            Text('• Check camera permissions'),
            Text('• Restart your device'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _retryCount = 0;
              _initializeWithRetry();
            },
            child: Text('RETRY'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pauseScanning() async {
    try {
      await _scanner.stopScanning();
      setState(() => _status = 'Scanning paused');
    } catch (e) {
      print('Error pausing scanning: $e');
    }
  }

  Future<void> _resumeScanning() async {
    try {
      await _scanner.startScanning();
      setState(() => _status = 'Ready - Point camera at QR code');
    } catch (e) {
      print('Error resuming scanning: $e');
      setState(() => _status = 'Error resuming scanner');
    }
  }

  Future<void> _stopScanning() async {
    try {
      await _scanner.stopScanning();
    } catch (e) {
      print('Error stopping scanning: $e');
    }
  }

  void _showScanResult(QRScanResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QR: ${result.content}'),
        action: SnackBarAction(
          label: 'COPY',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: result.content));
          },
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Robust QR Scanner'),
        actions: [
          if (_status.contains('error') || _status.contains('Fatal'))
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                _retryCount = 0;
                _initializeWithRetry();
              },
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_status.contains('error') || _status.contains('Fatal'))
              Icon(Icons.error, color: Colors.red, size: 48)
            else if (_status.contains('Ready'))
              Icon(Icons.qr_code_scanner, color: Colors.green, size: 48)
            else
              CircularProgressIndicator(),
            
            SizedBox(height: 16),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: _status.contains('error') ? Colors.red : null,
              ),
            ),
            
            if (_retryCount > 0) ...[
              SizedBox(height: 8),
              Text(
                'Retry attempt: $_retryCount/$_maxRetries',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

## 🎨 UI Integration

### Custom Scanner Overlay

```dart
class CustomOverlayScanner extends StatefulWidget {
  @override
  _CustomOverlayScannerState createState() => _CustomOverlayScannerState();
}

class _CustomOverlayScannerState extends State<CustomOverlayScanner>
    with TickerProviderStateMixin {
  final _scanner = QuickQRScannerPro.instance;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;
  bool _flashEnabled = false;

  @override
  void initState() {
    super.initState();
    
    _scanLineController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));
    
    _scanLineController.repeat(reverse: true);
    _initScanner();
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _initScanner() async {
    await _scanner.initialize();
    await _scanner.startScanning();
  }

  Future<void> _toggleFlash() async {
    try {
      final result = await _scanner.toggleFlashlight();
      setState(() {
        _flashEnabled = result['isOn'] ?? false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Flash not available: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview would go here in a real implementation
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black87,
          ),
          
          // Custom overlay
          _buildScannerOverlay(),
          
          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        child: Stack(
          children: [
            // Corner indicators
            ..._buildCornerIndicators(),
            
            // Scanning line animation
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                return Positioned(
                  left: 20,
                  right: 20,
                  top: 20 + (_scanLineAnimation.value * 210),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.red,
                          Colors.red,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red,
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerIndicators() {
    const double cornerSize = 20;
    const double cornerThickness = 3;
    
    return [
      // Top-left corner
      Positioned(
        left: 0,
        top: 0,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.green, width: cornerThickness),
              top: BorderSide(color: Colors.green, width: cornerThickness),
            ),
          ),
        ),
      ),
      
      // Top-right corner
      Positioned(
        right: 0,
        top: 0,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.green, width: cornerThickness),
              top: BorderSide(color: Colors.green, width: cornerThickness),
            ),
          ),
        ),
      ),
      
      // Bottom-left corner
      Positioned(
        left: 0,
        bottom: 0,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.green, width: cornerThickness),
              bottom: BorderSide(color: Colors.green, width: cornerThickness),
            ),
          ),
        ),
      ),
      
      // Bottom-right corner
      Positioned(
        right: 0,
        bottom: 0,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.green, width: cornerThickness),
              bottom: BorderSide(color: Colors.green, width: cornerThickness),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Flash toggle
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: IconButton(
              icon: Icon(
                _flashEnabled ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: _toggleFlash,
            ),
          ),
          
          // Gallery button (would open image picker in real implementation)
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: IconButton(
              icon: Icon(Icons.photo_library, color: Colors.white),
              onPressed: () {
                // Open image picker and scan selected image
                _openImagePicker();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openImagePicker() async {
    // This would use image_picker plugin in a real implementation
    // For this example, we'll simulate with a file dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image picker would open here')),
    );
  }
}
```

## ⚡ Performance Optimization

### Memory-Efficient Scanner

```dart
class OptimizedQRScanner extends StatefulWidget {
  @override
  _OptimizedQRScannerState createState() => _OptimizedQRScannerState();
}

class _OptimizedQRScannerState extends State<OptimizedQRScanner>
    with WidgetsBindingObserver {
  final _scanner = QuickQRScannerPro.instance;
  StreamSubscription<QRScanResult>? _subscription;
  Timer? _cooldownTimer;
  
  // Performance optimization settings
  static const Duration _scanCooldown = Duration(milliseconds: 500);
  static const int _maxResultsInMemory = 50;
  
  List<QRScanResult> _recentResults = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initOptimizedScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _cooldownTimer?.cancel();
    _scanner.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Optimize battery usage by stopping scanner when app is not active
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _pauseScanner();
        break;
      case AppLifecycleState.resumed:
        _resumeScanner();
        break;
      case AppLifecycleState.detached:
        _scanner.dispose();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _initOptimizedScanner() async {
    final config = QRScanConfig(
      enableMultiScan: false, // Disable for better performance
      scanInterval: _scanCooldown, // Limit scan frequency
      enabledFormats: ['qr'], // Limit to QR codes only for faster processing
    );

    await _scanner.initialize(config);
    
    _subscription = _scanner.onQRDetected.listen(
      _handleOptimizedScanResult,
      onError: (error) => print('Scan error: $error'),
    );
    
    await _scanner.startScanning();
  }

  void _handleOptimizedScanResult(QRScanResult result) {
    // Avoid processing if already processing or in cooldown
    if (_isProcessing || _cooldownTimer?.isActive == true) {
      return;
    }

    setState(() => _isProcessing = true);

    // Check for duplicate results (avoid processing same QR multiple times)
    if (_isDuplicateResult(result)) {
      setState(() => _isProcessing = false);
      return;
    }

    // Add result to memory-limited list
    _addResultWithLimit(result);

    // Process result
    _processResult(result);

    // Start cooldown timer
    _startCooldownTimer();

    setState(() => _isProcessing = false);
  }

  bool _isDuplicateResult(QRScanResult result) {
    // Check if same content was scanned recently (within last 5 results)
    final recentCheck = _recentResults.take(5);
    return recentCheck.any((r) => 
      r.content == result.content && 
      result.timestamp - r.timestamp < 3000 // 3 seconds
    );
  }

  void _addResultWithLimit(QRScanResult result) {
    _recentResults.insert(0, result);
    
    // Limit memory usage by keeping only recent results
    if (_recentResults.length > _maxResultsInMemory) {
      _recentResults = _recentResults.take(_maxResultsInMemory).toList();
    }
  }

  void _processResult(QRScanResult result) {
    // Process the result (show notification, save to database, etc.)
    _showResultSnackBar(result);
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(_scanCooldown, () {
      // Cooldown ended - ready for next scan
    });
  }

  Future<void> _pauseScanner() async {
    try {
      await _scanner.stopScanning();
    } catch (e) {
      print('Error pausing scanner: $e');
    }
  }

  Future<void> _resumeScanner() async {
    try {
      await _scanner.startScanning();
    } catch (e) {
      print('Error resuming scanner: $e');
    }
  }

  void _showResultSnackBar(QRScanResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QR: ${result.content}'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'COPY',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: result.content));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Optimized Scanner'),
        subtitle: Text('${_recentResults.length} scans'),
      ),
      body: Column(
        children: [
          // Performance indicators
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Icon(Icons.memory, color: Colors.blue),
                    Text('Memory'),
                    Text('${_recentResults.length}/$_maxResultsInMemory'),
                  ],
                ),
                Column(
                  children: [
                    Icon(
                      _isProcessing ? Icons.hourglass_empty : Icons.check,
                      color: _isProcessing ? Colors.orange : Colors.green,
                    ),
                    Text('Processing'),
                    Text(_isProcessing ? 'Busy' : 'Ready'),
                  ],
                ),
                Column(
                  children: [
                    Icon(
                      _cooldownTimer?.isActive == true 
                        ? Icons.timer 
                        : Icons.timer_off,
                      color: _cooldownTimer?.isActive == true 
                        ? Colors.orange 
                        : Colors.grey,
                    ),
                    Text('Cooldown'),
                    Text(_cooldownTimer?.isActive == true ? 'Active' : 'Ready'),
                  ],
                ),
              ],
            ),
          ),
          
          // Recent results list
          Expanded(
            child: ListView.builder(
              itemCount: _recentResults.length,
              itemBuilder: (context, index) {
                final result = _recentResults[index];
                final timestamp = DateTime.fromMillisecondsSinceEpoch(result.timestamp);
                
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    result.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Format: ${result.format} • '
                    'Time: ${timestamp.toString().substring(11, 19)}'
                  ),
                  trailing: Text(
                    '${(result.confidence * 100).toInt()}%',
                    style: TextStyle(
                      color: result.confidence > 0.8 
                        ? Colors.green 
                        : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _recentResults.clear();
          });
        },
        child: Icon(Icons.clear_all),
        tooltip: 'Clear Results',
      ),
    );
  }
}
```

## 🏢 Production Patterns

### Scanner Service Pattern

```dart
// scanner_service.dart
class QRScannerService {
  static final _instance = QRScannerService._internal();
  factory QRScannerService() => _instance;
  QRScannerService._internal();

  final _scanner = QuickQRScannerPro.instance;
  final _resultController = StreamController<QRScanResult>.broadcast();
  final _statusController = StreamController<ScannerStatus>.broadcast();
  
  Stream<QRScanResult> get onResult => _resultController.stream;
  Stream<ScannerStatus> get onStatusChanged => _statusController.stream;
  
  ScannerStatus _status = ScannerStatus.uninitialized;
  StreamSubscription<QRScanResult>? _subscription;

  Future<void> initialize() async {
    try {
      _updateStatus(ScannerStatus.initializing);
      
      final availability = await _scanner.checkAvailability();
      if (!availability['isAvailable']) {
        throw ScannerException('DEVICE_UNSUPPORTED', 'Camera not available');
      }

      final permissions = await _scanner.checkPermissions();
      if (permissions['status'] != 'granted') {
        _updateStatus(ScannerStatus.permissionRequired);
        
        final requested = await _scanner.requestPermissions();
        if (!requested['granted']) {
          throw ScannerException('PERMISSION_DENIED', 'Camera permission required');
        }
      }

      await _scanner.initialize();
      
      _subscription = _scanner.onQRDetected.listen(
        (result) {
          _resultController.add(result);
          _logScanResult(result);
        },
        onError: (error) {
          _updateStatus(ScannerStatus.error);
          _logError('Scan error', error);
        },
      );

      _updateStatus(ScannerStatus.ready);
      
    } catch (e) {
      _updateStatus(ScannerStatus.error);
      _logError('Initialization failed', e);
      rethrow;
    }
  }

  Future<void> startScanning() async {
    if (_status != ScannerStatus.ready) {
      throw StateError('Scanner not ready. Current status: $_status');
    }

    try {
      await _scanner.startScanning();
      _updateStatus(ScannerStatus.scanning);
    } catch (e) {
      _updateStatus(ScannerStatus.error);
      _logError('Start scanning failed', e);
      rethrow;
    }
  }

  Future<void> stopScanning() async {
    if (_status != ScannerStatus.scanning) return;

    try {
      await _scanner.stopScanning();
      _updateStatus(ScannerStatus.ready);
    } catch (e) {
      _logError('Stop scanning failed', e);
    }
  }

  Future<QRScanResult?> scanFromImagePath(String imagePath) async {
    try {
      _logInfo('Scanning image: $imagePath');
      return await _scanner.scanFromImage(imagePath);
    } catch (e) {
      _logError('Image scan failed', e);
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _scanner.dispose();
    await _resultController.close();
    await _statusController.close();
    _updateStatus(ScannerStatus.disposed);
  }

  void _updateStatus(ScannerStatus status) {
    _status = status;
    _statusController.add(status);
    _logInfo('Status changed: $status');
  }

  void _logScanResult(QRScanResult result) {
    print('✅ QR Scan Success: ${result.content} (${result.format})');
  }

  void _logError(String message, dynamic error) {
    print('❌ Scanner Error: $message - $error');
  }

  void _logInfo(String message) {
    print('ℹ️ Scanner: $message');
  }
}

enum ScannerStatus {
  uninitialized,
  initializing,
  permissionRequired,
  ready,
  scanning,
  error,
  disposed,
}

class ScannerException implements Exception {
  final String code;
  final String message;
  
  const ScannerException(this.code, this.message);
  
  @override
  String toString() => 'ScannerException($code): $message';
}
```

### Repository Pattern with Caching

```dart
// qr_scan_repository.dart
class QRScanRepository {
  final _scannerService = QRScannerService();
  final _cache = <String, CachedScanResult>{};
  final _maxCacheSize = 100;
  final _cacheValidityDuration = Duration(hours: 24);

  Future<QRScanResult?> scanFromImage(String imagePath) async {
    // Check cache first
    final cachedResult = _getCachedResult(imagePath);
    if (cachedResult != null) {
      print('Using cached result for: $imagePath');
      return cachedResult.result;
    }

    // Scan image
    final result = await _scannerService.scanFromImagePath(imagePath);
    
    // Cache result
    if (result != null) {
      _cacheResult(imagePath, result);
    }

    return result;
  }

  Stream<QRScanResult> get realTimeScanResults => _scannerService.onResult;
  Stream<ScannerStatus> get scannerStatus => _scannerService.onStatusChanged;

  Future<void> initialize() => _scannerService.initialize();
  Future<void> startScanning() => _scannerService.startScanning();
  Future<void> stopScanning() => _scannerService.stopScanning();

  CachedScanResult? _getCachedResult(String imagePath) {
    final cached = _cache[imagePath];
    if (cached == null) return null;
    
    // Check if cache is still valid
    if (DateTime.now().difference(cached.timestamp) > _cacheValidityDuration) {
      _cache.remove(imagePath);
      return null;
    }
    
    return cached;
  }

  void _cacheResult(String imagePath, QRScanResult result) {
    // Remove oldest entries if cache is full
    if (_cache.length >= _maxCacheSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    _cache[imagePath] = CachedScanResult(
      result: result,
      timestamp: DateTime.now(),
    );
  }

  void clearCache() {
    _cache.clear();
  }

  void dispose() {
    _scannerService.dispose();
    _cache.clear();
  }
}

class CachedScanResult {
  final QRScanResult result;
  final DateTime timestamp;

  const CachedScanResult({
    required this.result,
    required this.timestamp,
  });
}
```

### State Management with BLoC

```dart
// qr_scanner_bloc.dart
class QRScannerBloc extends Bloc<QRScannerEvent, QRScannerState> {
  final QRScanRepository _repository;
  StreamSubscription<QRScanResult>? _scanSubscription;
  StreamSubscription<ScannerStatus>? _statusSubscription;

  QRScannerBloc({required QRScanRepository repository})
      : _repository = repository,
        super(QRScannerInitial()) {
    
    on<InitializeScanner>(_onInitializeScanner);
    on<StartScanning>(_onStartScanning);
    on<StopScanning>(_onStopScanning);
    on<ScanFromImage>(_onScanFromImage);
    on<QRCodeDetected>(_onQRCodeDetected);
    on<ScannerStatusChanged>(_onScannerStatusChanged);
  }

  Future<void> _onInitializeScanner(
    InitializeScanner event,
    Emitter<QRScannerState> emit,
  ) async {
    emit(QRScannerLoading());

    try {
      await _repository.initialize();
      
      // Listen to scan results
      _scanSubscription = _repository.realTimeScanResults.listen(
        (result) => add(QRCodeDetected(result)),
      );

      // Listen to status changes
      _statusSubscription = _repository.scannerStatus.listen(
        (status) => add(ScannerStatusChanged(status)),
      );

      emit(QRScannerReady());
      
    } catch (e) {
      emit(QRScannerError(e.toString()));
    }
  }

  Future<void> _onStartScanning(
    StartScanning event,
    Emitter<QRScannerState> emit,
  ) async {
    try {
      await _repository.startScanning();
      emit(QRScannerScanning());
    } catch (e) {
      emit(QRScannerError(e.toString()));
    }
  }

  Future<void> _onStopScanning(
    StopScanning event,
    Emitter<QRScannerState> emit,
  ) async {
    try {
      await _repository.stopScanning();
      emit(QRScannerReady());
    } catch (e) {
      emit(QRScannerError(e.toString()));
    }
  }

  Future<void> _onScanFromImage(
    ScanFromImage event,
    Emitter<QRScannerState> emit,
  ) async {
    emit(QRScannerProcessingImage());

    try {
      final result = await _repository.scanFromImage(event.imagePath);
      
      if (result != null) {
        emit(QRScannerImageResult(result));
      } else {
        emit(QRScannerImageNoResult());
      }
      
    } catch (e) {
      emit(QRScannerError(e.toString()));
    }
  }

  void _onQRCodeDetected(
    QRCodeDetected event,
    Emitter<QRScannerState> emit,
  ) {
    emit(QRScannerResult(event.result));
  }

  void _onScannerStatusChanged(
    ScannerStatusChanged event,
    Emitter<QRScannerState> emit,
  ) {
    switch (event.status) {
      case ScannerStatus.ready:
        emit(QRScannerReady());
        break;
      case ScannerStatus.scanning:
        emit(QRScannerScanning());
        break;
      case ScannerStatus.error:
        emit(QRScannerError('Scanner error occurred'));
        break;
      default:
        break;
    }
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    _statusSubscription?.cancel();
    _repository.dispose();
    return super.close();
  }
}

// Events
abstract class QRScannerEvent extends Equatable {
  const QRScannerEvent();
  
  @override
  List<Object?> get props => [];
}

class InitializeScanner extends QRScannerEvent {}
class StartScanning extends QRScannerEvent {}
class StopScanning extends QRScannerEvent {}
class ScanFromImage extends QRScannerEvent {
  final String imagePath;
  
  const ScanFromImage(this.imagePath);
  
  @override
  List<Object> get props => [imagePath];
}

class QRCodeDetected extends QRScannerEvent {
  final QRScanResult result;
  
  const QRCodeDetected(this.result);
  
  @override
  List<Object> get props => [result];
}

class ScannerStatusChanged extends QRScannerEvent {
  final ScannerStatus status;
  
  const ScannerStatusChanged(this.status);
  
  @override
  List<Object> get props => [status];
}

// States
abstract class QRScannerState extends Equatable {
  const QRScannerState();
  
  @override
  List<Object?> get props => [];
}

class QRScannerInitial extends QRScannerState {}
class QRScannerLoading extends QRScannerState {}
class QRScannerReady extends QRScannerState {}
class QRScannerScanning extends QRScannerState {}
class QRScannerResult extends QRScannerState {
  final QRScanResult result;
  
  const QRScannerResult(this.result);
  
  @override
  List<Object> get props => [result];
}

class QRScannerProcessingImage extends QRScannerState {}
class QRScannerImageResult extends QRScannerState {
  final QRScanResult result;
  
  const QRScannerImageResult(this.result);
  
  @override
  List<Object> get props => [result];
}

class QRScannerImageNoResult extends QRScannerState {}
class QRScannerError extends QRScannerState {
  final String error;
  
  const QRScannerError(this.error);
  
  @override
  List<Object> get props => [error];
}
```

---

For more detailed information about specific methods and classes, see the [API Reference](API_REFERENCE.md).

These examples demonstrate various usage patterns and best practices for integrating QuickQR Scanner Pro into your Flutter applications. Choose the patterns that best fit your application's architecture and requirements.