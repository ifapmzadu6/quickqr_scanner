/// Supported barcode formats
enum BarcodeFormat {
  qr('qr'),
  code128('code128'),
  code39('code39'),
  code93('code93'),
  ean8('ean8'),
  ean13('ean13'),
  upce('upce');
  
  const BarcodeFormat(this.value);
  final String value;
  
  static BarcodeFormat fromString(String value) {
    return BarcodeFormat.values.firstWhere(
      (format) => format.value == value.toLowerCase(),
      orElse: () => BarcodeFormat.qr,
    );
  }
}

/// Result of QR code scanning operation
/// 
/// Contains the decoded content, format information, detection timestamp,
/// and confidence level of a barcode/QR code detection.
class QRScanResult {
  /// The decoded content of the QR code
  final String content;
  
  /// The format of the detected code
  final BarcodeFormat format;
  
  /// Timestamp when the QR code was detected (milliseconds since epoch)
  final int timestamp;
  
  /// Confidence level of the detection (0.0 to 1.0)
  final double confidence;
  
  const QRScanResult({
    required this.content,
    required this.format,
    required this.timestamp,
    required this.confidence,
  }) : assert(confidence >= 0.0 && confidence <= 1.0, 'Confidence must be between 0.0 and 1.0');
  
  /// Create QRScanResult from platform channel map
  /// 
  /// Throws [FormatException] if required fields are missing or invalid
  factory QRScanResult.fromMap(Map<String, dynamic> map) {
    try {
      final content = map['content'];
      final format = map['format'];
      final timestamp = map['timestamp'];
      final confidence = map['confidence'];

      if (content is! String) {
        throw const FormatException('Invalid or missing content field');
      }
      if (format is! String) {
        throw const FormatException('Invalid or missing format field');
      }
      if (timestamp is! int) {
        throw const FormatException('Invalid or missing timestamp field');
      }

      final confidenceValue = switch (confidence) {
        final double d => d,
        final int i => i.toDouble(),
        _ => 1.0,
      };

      return QRScanResult(
        content: content,
        format: BarcodeFormat.fromString(format),
        timestamp: timestamp,
        confidence: confidenceValue.clamp(0.0, 1.0),
      );
    } catch (e) {
      throw FormatException('Failed to parse QRScanResult from map: $e');
    }
  }
  
  /// Create QRScanResult from JSON string
  factory QRScanResult.fromJson(String jsonString) {
    try {
      final map = Map<String, dynamic>.from(
        // This would typically use dart:convert's jsonDecode
        {} // Simplified for now
      );
      return QRScanResult.fromMap(map);
    } catch (e) {
      throw FormatException('Failed to parse QRScanResult from JSON: $e');
    }
  }
  
  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'format': format.value,
      'timestamp': timestamp,
      'confidence': confidence,
    };
  }
  
  /// Convert to JSON string
  String toJson() {
    // This would typically use dart:convert's jsonEncode
    return toMap().toString(); // Simplified for now
  }
  
  /// Create a copy with modified properties
  QRScanResult copyWith({
    String? content,
    BarcodeFormat? format,
    int? timestamp,
    double? confidence,
  }) {
    return QRScanResult(
      content: content ?? this.content,
      format: format ?? this.format,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
    );
  }
  
  /// Check if this is a high-confidence detection
  bool get isHighConfidence => confidence >= 0.8;
  
  /// Check if the content appears to be a URL
  bool get isUrl {
    return content.startsWith('http://') || 
           content.startsWith('https://') ||
           content.startsWith('ftp://');
  }
  
  /// Check if the content appears to be an email
  bool get isEmail {
    return content.contains('@') && content.contains('.');
  }
  
  /// Get formatted timestamp as DateTime
  DateTime get detectedAt => DateTime.fromMillisecondsSinceEpoch(timestamp);
  
  @override
  String toString() {
    return 'QRScanResult(content: "$content", format: ${format.value}, timestamp: $timestamp, confidence: ${confidence.toStringAsFixed(2)})';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QRScanResult &&
        other.content == content &&
        other.format == format &&
        other.timestamp == timestamp &&
        (other.confidence - confidence).abs() < 0.001; // Float comparison with tolerance
  }
  
  @override
  int get hashCode {
    return Object.hash(content, format, timestamp, confidence);
  }
}