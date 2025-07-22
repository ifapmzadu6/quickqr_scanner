import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickqr_scanner/quickqr_scanner.dart';

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
  final _scanner = QuickQRScanner.instance;
  
  // State variables
  bool _isInitialized = false;
  bool _isScanning = false;
  String _status = 'タップしてスキャナーを初期化';
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
          ? 'デバイス対応確認済み - 初期化してください' 
          : 'このデバイスはQRスキャンに対応していません';
      });
    } catch (e) {
      setState(() {
        _status = 'デバイス確認エラー: $e';
      });
    }
  }

  // Initialize scanner
  Future<void> _initializeScanner() async {
    if (_isInitialized) return;
    
    setState(() {
      _status = 'カメラ権限を確認中...';
    });

    try {
      // Check permissions
      final permissions = await _scanner.checkPermissions();
      if (permissions['status'] != 'granted') {
        setState(() {
          _status = '権限が必要です - 設定から許可してください';
        });
        return;
      }

      // Initialize scanner
      setState(() {
        _status = 'スキャナーを初期化中...';
      });
      
      final result = await _scanner.initialize();
      
      setState(() {
        _isInitialized = true;
        _status = '初期化完了 - スキャンを開始できます';
      });

      print('Scanner initialized: $result');

    } catch (e) {
      setState(() {
        _status = '初期化エラー: $e';
      });
    }
  }

  // Start scanning
  Future<void> _startScanning() async {
    if (!_isInitialized || _isScanning) return;

    try {
      setState(() {
        _status = 'スキャン開始中...';
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
            _status = 'スキャンエラー: $error';
          });
        },
      );

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
        _status = 'スキャン停止 - 再開可能';
      });

    } catch (e) {
      setState(() {
        _status = 'スキャン停止エラー: $e';
      });
    }
  }

  // Toggle flashlight
  Future<void> _toggleFlashlight() async {
    if (!_isScanning) return;
    
    try {
      final result = await _scanner.toggleFlashlight();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('フラッシュライト: ${result['message']}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('フラッシュライトエラー: $e')),
      );
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
              tooltip: 'フラッシュライト切替',
            ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _scanResults.isNotEmpty ? _clearResults : null,
            tooltip: '結果をクリア',
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
                      'ステータス',
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
                        'デバイス情報',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '対応: ${_deviceInfo!['isSupported']}\n'
                        'カメラ: ${_deviceInfo!['isAvailable']}\n'
                        'フレームワーク: ${_deviceInfo!['deviceInfo']?['framework'] ?? 'Unknown'}',
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
                    label: const Text('初期化'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isInitialized && !_isScanning ? _startScanning : null,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('スキャン開始'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? _stopScanning : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('停止'),
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
              'スキャン結果 (${_scanResults.length})',
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
                              'QRコードをスキャンしてください',
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
                            'フォーマット: ${result.format.toUpperCase()}\n'
                            '時間: ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}:'
                            '${timestamp.second.toString().padLeft(2, '0')}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: result.content));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('クリップボードにコピーしました'),
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