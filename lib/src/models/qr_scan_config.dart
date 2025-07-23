import 'qr_scan_result.dart';

/// Configuration for QR scanner
/// 
/// Provides settings for camera behavior, supported formats,
/// and performance tuning parameters.
class QRScanConfig {
  /// Enable flashlight on initialization (if supported)
  final bool enableFlashlight;
  
  /// Supported barcode formats for detection
  final Set<BarcodeFormat> formats;
  
  /// Detection cooldown in milliseconds (minimum 100ms, maximum 5000ms)
  final int detectionCooldown;
  
  /// Auto-focus enabled
  final bool autoFocus;
  
  /// Enable vibration feedback on detection (mobile only)
  final bool enableVibration;
  
  /// Enable audio feedback on detection
  final bool enableAudio;
  
  /// Minimum confidence threshold for detection (0.0 to 1.0)
  final double minConfidence;
  
  /// Default configuration constants
  static const int defaultCooldown = 1000;
  static const double defaultMinConfidence = 0.5;
  static const Set<BarcodeFormat> defaultFormats = {
    BarcodeFormat.qr,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.ean13,
  };
  
  const QRScanConfig({
    this.enableFlashlight = false,
    this.formats = defaultFormats,
    this.detectionCooldown = defaultCooldown,
    this.autoFocus = true,
    this.enableVibration = true,
    this.enableAudio = false,
    this.minConfidence = defaultMinConfidence,
  }) : assert(detectionCooldown >= 100 && detectionCooldown <= 5000, 
              'Detection cooldown must be between 100ms and 5000ms'),
       assert(minConfidence >= 0.0 && minConfidence <= 1.0,
              'Minimum confidence must be between 0.0 and 1.0');
  
  /// Create a performance-optimized configuration
  factory QRScanConfig.performance() {
    return const QRScanConfig(
      detectionCooldown: 500,
      formats: {BarcodeFormat.qr}, // QR only for speed
      autoFocus: true,
      enableVibration: false,
      enableAudio: false,
      minConfidence: 0.7,
    );
  }
  
  /// Create a comprehensive configuration supporting all formats
  factory QRScanConfig.comprehensive() {
    return const QRScanConfig(
      detectionCooldown: 800,
      formats: {
        BarcodeFormat.qr,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.ean8,
        BarcodeFormat.ean13,
        BarcodeFormat.upce,
      },
      autoFocus: true,
      enableVibration: true,
      enableAudio: true,
      minConfidence: 0.6,
    );
  }
  
  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'enableFlashlight': enableFlashlight,
      'formats': formats.map((f) => f.value).toList(),
      'detectionCooldown': detectionCooldown,
      'autoFocus': autoFocus,
      'enableVibration': enableVibration,
      'enableAudio': enableAudio,
      'minConfidence': minConfidence,
    };
  }
  
  /// Create from map with validation
  factory QRScanConfig.fromMap(Map<String, dynamic> map) {
    try {
      final formatsList = map['formats'] as List?;
      final formatsSet = formatsList?.cast<String>()
        .map((f) => BarcodeFormat.fromString(f))
        .toSet() ?? defaultFormats;
      
      final cooldown = map['detectionCooldown'] as int? ?? defaultCooldown;
      final minConf = (map['minConfidence'] as num?)?.toDouble() ?? defaultMinConfidence;
      
      return QRScanConfig(
        enableFlashlight: map['enableFlashlight'] as bool? ?? false,
        formats: formatsSet.isEmpty ? defaultFormats : formatsSet,
        detectionCooldown: cooldown.clamp(100, 5000),
        autoFocus: map['autoFocus'] as bool? ?? true,
        enableVibration: map['enableVibration'] as bool? ?? true,
        enableAudio: map['enableAudio'] as bool? ?? false,
        minConfidence: minConf.clamp(0.0, 1.0),
      );
    } catch (e) {
      throw FormatException('Failed to parse QRScanConfig from map: $e');
    }
  }
  
  /// Copy with new values
  QRScanConfig copyWith({
    bool? enableFlashlight,
    Set<BarcodeFormat>? formats,
    int? detectionCooldown,
    bool? autoFocus,
    bool? enableVibration,
    bool? enableAudio,
    double? minConfidence,
  }) {
    return QRScanConfig(
      enableFlashlight: enableFlashlight ?? this.enableFlashlight,
      formats: formats ?? this.formats,
      detectionCooldown: detectionCooldown ?? this.detectionCooldown,
      autoFocus: autoFocus ?? this.autoFocus,
      enableVibration: enableVibration ?? this.enableVibration,
      enableAudio: enableAudio ?? this.enableAudio,
      minConfidence: minConfidence ?? this.minConfidence,
    );
  }
  
  /// Validate configuration and return list of warnings
  List<String> validate() {
    final warnings = <String>[];
    
    if (detectionCooldown < 300) {
      warnings.add('Very short detection cooldown (${detectionCooldown}ms) may impact performance');
    }
    
    if (minConfidence < 0.3) {
      warnings.add('Very low confidence threshold (${minConfidence.toStringAsFixed(2)}) may result in false positives');
    }
    
    if (formats.length > 5) {
      warnings.add('Many formats enabled (${formats.length}) may slow down detection');
    }
    
    if (enableFlashlight) {
      warnings.add('Flashlight enabled by default may drain battery faster');
    }
    
    return warnings;
  }
  
  /// Check if configuration is optimized for performance
  bool get isPerformanceOptimized {
    return formats.length <= 3 &&
           detectionCooldown >= 500 &&
           minConfidence >= 0.6;
  }
  
  /// Check if configuration supports comprehensive format detection
  bool get isComprehensive {
    return formats.length >= 5;
  }
  
  @override
  String toString() {
    return 'QRScanConfig('
           'enableFlashlight: $enableFlashlight, '
           'formats: ${formats.map((f) => f.value).toList()}, '
           'detectionCooldown: ${detectionCooldown}ms, '
           'autoFocus: $autoFocus, '
           'enableVibration: $enableVibration, '
           'enableAudio: $enableAudio, '
           'minConfidence: ${minConfidence.toStringAsFixed(2)}'
           ')';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QRScanConfig &&
        other.enableFlashlight == enableFlashlight &&
        other.formats.length == formats.length &&
        other.formats.containsAll(formats) &&
        other.detectionCooldown == detectionCooldown &&
        other.autoFocus == autoFocus &&
        other.enableVibration == enableVibration &&
        other.enableAudio == enableAudio &&
        (other.minConfidence - minConfidence).abs() < 0.001;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      enableFlashlight,
      formats,
      detectionCooldown,
      autoFocus,
      enableVibration,
      enableAudio,
      minConfidence,
    );
  }
}