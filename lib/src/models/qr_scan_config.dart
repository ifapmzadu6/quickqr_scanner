/// Configuration for QR scanner
class QRScanConfig {
  /// Enable flashlight (if supported)
  final bool enableFlashlight;
  
  /// Supported barcode formats
  final List<String> formats;
  
  /// Detection cooldown in milliseconds
  final int detectionCooldown;
  
  /// Auto-focus enabled
  final bool autoFocus;
  
  const QRScanConfig({
    this.enableFlashlight = false,
    this.formats = const ['qr', 'code128', 'code39', 'ean13'],
    this.detectionCooldown = 1000,
    this.autoFocus = true,
  });
  
  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'enableFlashlight': enableFlashlight,
      'formats': formats,
      'detectionCooldown': detectionCooldown,
      'autoFocus': autoFocus,
    };
  }
  
  /// Create from map
  factory QRScanConfig.fromMap(Map<String, dynamic> map) {
    return QRScanConfig(
      enableFlashlight: map['enableFlashlight'] as bool? ?? false,
      formats: List<String>.from(map['formats'] as List? ?? ['qr']),
      detectionCooldown: map['detectionCooldown'] as int? ?? 1000,
      autoFocus: map['autoFocus'] as bool? ?? true,
    );
  }
  
  /// Copy with new values
  QRScanConfig copyWith({
    bool? enableFlashlight,
    List<String>? formats,
    int? detectionCooldown,
    bool? autoFocus,
  }) {
    return QRScanConfig(
      enableFlashlight: enableFlashlight ?? this.enableFlashlight,
      formats: formats ?? this.formats,
      detectionCooldown: detectionCooldown ?? this.detectionCooldown,
      autoFocus: autoFocus ?? this.autoFocus,
    );
  }
  
  @override
  String toString() {
    return 'QRScanConfig(enableFlashlight: $enableFlashlight, formats: $formats, detectionCooldown: $detectionCooldown, autoFocus: $autoFocus)';
  }
}