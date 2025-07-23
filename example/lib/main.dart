import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickqr_scanner_plugin/quickqr_scanner_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickQR Scanner Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scanner = QuickqrScannerPlugin();
  
  // State variables
  bool _isInitialized = false;
  bool _isScanning = false;
  String _status = 'Tap to initialize scanner';
  List<QRScanResult> _scanResults = [];
  StreamSubscription<QRScanResult>? _scanSubscription;
  Map<String, dynamic>? _deviceInfo;

  @override
  void initState() {
    super.initState();
    _checkDeviceCapabilities();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanner.dispose();
    super.dispose();
  }

  // Device capabilities check
  Future<void> _checkDeviceCapabilities() async {
    try {
      final availability = await _scanner.checkAvailability();
      setState(() {
        _deviceInfo = availability;
        _status = availability['isAvailable'] == true 
          ? 'Device compatible - please initialize' 
          : 'This device does not support QR scanning';
      });
    } catch (e) {
      setState(() {
        _status = 'Device check error: $e';
      });
    }
  }

  // Initialize scanner
  Future<void> _initializeScanner() async {
    if (_isInitialized) return;
    
    setState(() {
      _status = 'Checking camera permissions...';
    });

    try {
      // Check permissions
      final permissions = await _scanner.checkPermissions();
      if (permissions['status'] != 'granted') {
        setState(() {
          _status = 'Permission required - please allow in settings';
        });
        return;
      }

      // Initialize scanner
      setState(() {
        _status = 'Initializing scanner...';
      });
      
      final result = await _scanner.initialize();
      
      setState(() {
        _isInitialized = true;
        _status = 'Initialization complete - ready to scan';
      });

      debugPrint('Scanner initialized: $result');

    } catch (e) {
      setState(() {
        _status = 'Initialization error: $e';
      });
    }
  }

  // Start scanning
  Future<void> _startScanning() async {
    if (!_isInitialized || _isScanning) return;

    try {
      setState(() {
        _status = 'Starting scan...';
      });

      // Listen to scan results
      _scanSubscription = _scanner.onQRDetected.listen(
        (result) {
          setState(() {
            _scanResults.insert(0, result);
            if (_scanResults.length > 10) {
              _scanResults = _scanResults.take(10).toList();
            }
          });
        },
        onError: (error) {
          setState(() {
            _status = 'Scan error: $error';
          });
        },
      );

      await _scanner.startScanning();
      
      setState(() {
        _isScanning = true;
        _status = 'Scanning - point camera at QR code';
      });

    } catch (e) {
      setState(() {
        _status = 'Scan start error: $e';
      });
    }
  }

  // Stop scanning
  Future<void> _stopScanning() async {
    if (!_isScanning) return;

    try {
      await _scanner.stopScanning();
      _scanSubscription?.cancel();
      _scanSubscription = null;
      
      setState(() {
        _isScanning = false;
        _status = 'Scan stopped - can resume';
      });

    } catch (e) {
      setState(() {
        _status = 'Scan stop error: $e';
      });
    }
  }

  // Toggle flashlight
  Future<void> _toggleFlashlight() async {
    if (!_isScanning) return;
    
    try {
      final result = await _scanner.toggleFlashlight();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flashlight: ${result['message']}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flashlight error: $e')),
        );
      }
    }
  }

  // Clear scan results
  void _clearResults() {
    setState(() {
      _scanResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickQR Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isScanning)
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: _toggleFlashlight,
              tooltip: 'Toggle flashlight',
            ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _scanResults.isNotEmpty ? _clearResults : null,
            tooltip: 'Clear results',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        color: _isScanning ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    // Device info
                    if (_deviceInfo != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Device Info',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supported: ${_deviceInfo!['isSupported']}\n'
                        'Camera: ${_deviceInfo!['isAvailable']}\n'
                        'Framework: ${_deviceInfo!['deviceInfo']?['framework'] ?? 'Unknown'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Control buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !_isInitialized ? _initializeScanner : null,
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('Initialize'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isInitialized && !_isScanning ? _startScanning : null,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Start Scan'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? _stopScanning : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Scan results
            Text(
              'Scan Results (${_scanResults.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: _scanResults.isEmpty
                ? Card(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Please scan a QR code',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final result = _scanResults[index];
                      final timestamp = DateTime.fromMillisecondsSinceEpoch(result.timestamp);
                      
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            result.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Format: ${result.format.value.toUpperCase()}\n'
                            'Time: ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}:'
                            '${timestamp.second.toString().padLeft(2, '0')}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: result.content));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}