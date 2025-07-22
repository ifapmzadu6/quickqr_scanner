/// Result of QR code scanning operation
class QRScanResult {
  /// The decoded content of the QR code
  final String content;
  
  /// The format of the detected code (qr, code128, etc.)
  final String format;
  
  /// Timestamp when the QR code was detected (milliseconds since epoch)
  final int timestamp;
  
  /// Confidence level of the detection (0.0 to 1.0)
  final double confidence;
  
  const QRScanResult({
    required this.content,
    required this.format,
    required this.timestamp,
    required this.confidence,
  });
  
  /// Create QRScanResult from platform channel map
  factory QRScanResult.fromMap(Map<String, dynamic> map) {
    return QRScanResult(
      content: map['content'] as String,
      format: map['format'] as String,
      timestamp: map['timestamp'] as int,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
  
  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'format': format,
      'timestamp': timestamp,
      'confidence': confidence,
    };
  }
  
  @override
  String toString() {
    return 'QRScanResult(content: $content, format: $format, timestamp: $timestamp, confidence: $confidence)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QRScanResult &&
        other.content == content &&
        other.format == format &&
        other.timestamp == timestamp &&
        other.confidence == confidence;
  }
  
  @override
  int get hashCode {
    return Object.hash(content, format, timestamp, confidence);
  }
}