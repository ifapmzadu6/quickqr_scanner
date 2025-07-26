
/// Camera control configuration for enhanced QR scanning
/// 
/// Provides advanced camera controls for optimal QR code detection
/// including zoom, macro mode, focus control, and exposure settings.
class CameraControlConfig {
  /// Zoom level (1.0 = no zoom, higher values = more zoom)
  /// iOS: Supports up to device maximum (typically 2-10x)
  /// Android: Supports digital zoom based on device capabilities
  final double zoomLevel;
  
  /// Enable macro mode for close-up scanning
  /// Optimizes focus and settings for small QR codes at close distance
  final bool enableMacroMode;
  
  /// Focus mode for scanning
  final FocusMode focusMode;
  
  /// Focus point for manual focus (normalized coordinates 0.0-1.0)
  /// Only used when focusMode is FocusMode.manual
  final FocusPoint? focusPoint;
  
  /// Auto-exposure mode
  final ExposureMode exposureMode;
  
  /// Manual exposure compensation (-2.0 to +2.0)
  /// Only used when exposureMode is ExposureMode.manual
  final double? exposureCompensation;
  
  /// Preferred camera resolution
  final CameraResolution resolution;
  
  /// Enable image stabilization (if supported)
  final bool enableStabilization;
  
  /// Preferred camera position
  final CameraPosition cameraPosition;
  
  /// Auto white balance mode
  final WhiteBalanceMode whiteBalanceMode;
  
  /// Frame rate preference (fps)
  final int preferredFrameRate;
  
  /// Enable HDR mode for better contrast
  final bool enableHDR;
  
  /// Default configuration constants
  static const double defaultZoom = 1.0;
  static const double minZoom = 1.0;
  static const double maxZoom = 10.0;
  static const int defaultFrameRate = 30;
  
  const CameraControlConfig({
    this.zoomLevel = defaultZoom,
    this.enableMacroMode = false,
    this.focusMode = FocusMode.auto,
    this.focusPoint,
    this.exposureMode = ExposureMode.auto,
    this.exposureCompensation,
    this.resolution = CameraResolution.medium,
    this.enableStabilization = true,
    this.cameraPosition = CameraPosition.back,
    this.whiteBalanceMode = WhiteBalanceMode.auto,
    this.preferredFrameRate = defaultFrameRate,
    this.enableHDR = false,
  }) : assert(zoomLevel >= minZoom && zoomLevel <= maxZoom,
              'Zoom level must be between $minZoom and $maxZoom'),
       assert(focusPoint == null || focusMode == FocusMode.manual,
              'Focus point can only be set with manual focus mode'),
       assert(exposureCompensation == null || exposureMode == ExposureMode.manual,
              'Exposure compensation can only be set with manual exposure mode'),
       assert(exposureCompensation == null || 
              (exposureCompensation >= -2.0 && exposureCompensation <= 2.0),
              'Exposure compensation must be between -2.0 and +2.0');
  
  /// Create a configuration optimized for macro QR scanning
  factory CameraControlConfig.macro() {
    return const CameraControlConfig(
      zoomLevel: 1.5,
      enableMacroMode: true,
      focusMode: FocusMode.auto,
      exposureMode: ExposureMode.auto,
      resolution: CameraResolution.high,
      enableStabilization: true,
      enableHDR: true,
    );
  }
  
  /// Create a configuration optimized for distant QR scanning
  factory CameraControlConfig.distant() {
    return const CameraControlConfig(
      zoomLevel: 2.0,
      enableMacroMode: false,
      focusMode: FocusMode.infinity,
      exposureMode: ExposureMode.auto,
      resolution: CameraResolution.high,
      enableStabilization: true,
      preferredFrameRate: 60,
    );
  }
  
  /// Create a configuration optimized for low-light conditions
  factory CameraControlConfig.lowLight() {
    return const CameraControlConfig(
      zoomLevel: 1.0,
      enableMacroMode: false,
      focusMode: FocusMode.auto,
      exposureMode: ExposureMode.manual,
      exposureCompensation: 0.5,
      resolution: CameraResolution.medium,
      enableStabilization: true,
      enableHDR: true,
      preferredFrameRate: 24,
    );
  }
  
  /// Create a performance-optimized configuration
  factory CameraControlConfig.performance() {
    return const CameraControlConfig(
      zoomLevel: 1.0,
      enableMacroMode: false,
      focusMode: FocusMode.auto,
      exposureMode: ExposureMode.auto,
      resolution: CameraResolution.low,
      enableStabilization: false,
      enableHDR: false,
      preferredFrameRate: 60,
    );
  }
  
  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'zoomLevel': zoomLevel,
      'enableMacroMode': enableMacroMode,
      'focusMode': focusMode.value,
      'focusPoint': focusPoint?.toMap(),
      'exposureMode': exposureMode.value,
      'exposureCompensation': exposureCompensation,
      'resolution': resolution.value,
      'enableStabilization': enableStabilization,
      'cameraPosition': cameraPosition.value,
      'whiteBalanceMode': whiteBalanceMode.value,
      'preferredFrameRate': preferredFrameRate,
      'enableHDR': enableHDR,
    };
  }
  
  /// Create from map with validation
  factory CameraControlConfig.fromMap(Map<String, dynamic> map) {
    try {
      final zoom = (map['zoomLevel'] as num?)?.toDouble() ?? defaultZoom;
      final frameRate = map['preferredFrameRate'] as int? ?? defaultFrameRate;
      final expCompensation = (map['exposureCompensation'] as num?)?.toDouble();
      
      FocusPoint? focusPoint;
      if (map['focusPoint'] != null) {
        focusPoint = FocusPoint.fromMap(map['focusPoint'] as Map<String, dynamic>);
      }
      
      return CameraControlConfig(
        zoomLevel: zoom.clamp(minZoom, maxZoom),
        enableMacroMode: map['enableMacroMode'] as bool? ?? false,
        focusMode: FocusMode.fromString(map['focusMode'] as String? ?? 'auto'),
        focusPoint: focusPoint,
        exposureMode: ExposureMode.fromString(map['exposureMode'] as String? ?? 'auto'),
        exposureCompensation: expCompensation?.clamp(-2.0, 2.0),
        resolution: CameraResolution.fromString(map['resolution'] as String? ?? 'medium'),
        enableStabilization: map['enableStabilization'] as bool? ?? true,
        cameraPosition: CameraPosition.fromString(map['cameraPosition'] as String? ?? 'back'),
        whiteBalanceMode: WhiteBalanceMode.fromString(map['whiteBalanceMode'] as String? ?? 'auto'),
        preferredFrameRate: frameRate.clamp(1, 120),
        enableHDR: map['enableHDR'] as bool? ?? false,
      );
    } catch (e) {
      throw FormatException('Failed to parse CameraControlConfig from map: $e');
    }
  }
  
  /// Copy with new values
  CameraControlConfig copyWith({
    double? zoomLevel,
    bool? enableMacroMode,
    FocusMode? focusMode,
    FocusPoint? focusPoint,
    ExposureMode? exposureMode,
    double? exposureCompensation,
    CameraResolution? resolution,
    bool? enableStabilization,
    CameraPosition? cameraPosition,
    WhiteBalanceMode? whiteBalanceMode,
    int? preferredFrameRate,
    bool? enableHDR,
  }) {
    return CameraControlConfig(
      zoomLevel: zoomLevel ?? this.zoomLevel,
      enableMacroMode: enableMacroMode ?? this.enableMacroMode,
      focusMode: focusMode ?? this.focusMode,
      focusPoint: focusPoint ?? this.focusPoint,
      exposureMode: exposureMode ?? this.exposureMode,
      exposureCompensation: exposureCompensation ?? this.exposureCompensation,
      resolution: resolution ?? this.resolution,
      enableStabilization: enableStabilization ?? this.enableStabilization,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      whiteBalanceMode: whiteBalanceMode ?? this.whiteBalanceMode,
      preferredFrameRate: preferredFrameRate ?? this.preferredFrameRate,
      enableHDR: enableHDR ?? this.enableHDR,
    );
  }
  
  /// Validate configuration and return list of warnings
  List<String> validate() {
    final warnings = <String>[];
    
    if (zoomLevel > 3.0) {
      warnings.add('High zoom level (${zoomLevel.toStringAsFixed(1)}x) may reduce image quality');
    }
    
    if (enableMacroMode && zoomLevel > 2.0) {
      warnings.add('High zoom with macro mode may make focusing difficult');
    }
    
    if (preferredFrameRate > 60) {
      warnings.add('High frame rate (${preferredFrameRate}fps) may drain battery faster');
    }
    
    if (resolution == CameraResolution.high && preferredFrameRate > 30) {
      warnings.add('High resolution with high frame rate may impact performance');
    }
    
    if (enableHDR && preferredFrameRate > 30) {
      warnings.add('HDR mode with high frame rate may reduce processing speed');
    }
    
    return warnings;
  }
  
  /// Check if configuration is optimized for close-up scanning
  bool get isOptimizedForCloseUp {
    return enableMacroMode || zoomLevel >= 1.5;
  }
  
  /// Check if configuration is optimized for distant scanning
  bool get isOptimizedForDistant {
    return zoomLevel >= 2.0 && focusMode == FocusMode.infinity;
  }
  
  /// Check if configuration is optimized for performance
  bool get isPerformanceOptimized {
    return resolution == CameraResolution.low &&
           !enableHDR &&
           !enableStabilization &&
           preferredFrameRate >= 60;
  }
  
  @override
  String toString() {
    return 'CameraControlConfig('
           'zoomLevel: ${zoomLevel.toStringAsFixed(1)}x, '
           'enableMacroMode: $enableMacroMode, '
           'focusMode: ${focusMode.value}, '
           'exposureMode: ${exposureMode.value}, '
           'resolution: ${resolution.value}, '
           'cameraPosition: ${cameraPosition.value}, '
           'frameRate: ${preferredFrameRate}fps'
           ')';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CameraControlConfig &&
        (other.zoomLevel - zoomLevel).abs() < 0.001 &&
        other.enableMacroMode == enableMacroMode &&
        other.focusMode == focusMode &&
        other.focusPoint == focusPoint &&
        other.exposureMode == exposureMode &&
        ((other.exposureCompensation == null && exposureCompensation == null) ||
         (other.exposureCompensation != null && exposureCompensation != null &&
          (other.exposureCompensation! - exposureCompensation!).abs() < 0.001)) &&
        other.resolution == resolution &&
        other.enableStabilization == enableStabilization &&
        other.cameraPosition == cameraPosition &&
        other.whiteBalanceMode == whiteBalanceMode &&
        other.preferredFrameRate == preferredFrameRate &&
        other.enableHDR == enableHDR;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      zoomLevel,
      enableMacroMode,
      focusMode,
      focusPoint,
      exposureMode,
      exposureCompensation,
      resolution,
      enableStabilization,
      cameraPosition,
      whiteBalanceMode,
      preferredFrameRate,
      enableHDR,
    );
  }
}

/// Focus mode for camera control
enum FocusMode {
  auto('auto'),
  manual('manual'),
  infinity('infinity'),
  macro('macro');
  
  const FocusMode(this.value);
  final String value;
  
  static FocusMode fromString(String value) {
    return FocusMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => FocusMode.auto,
    );
  }
}

/// Focus point for manual focus control
class FocusPoint {
  final double x; // Normalized coordinate (0.0-1.0)
  final double y; // Normalized coordinate (0.0-1.0)
  
  const FocusPoint(this.x, this.y)
    : assert(x >= 0.0 && x <= 1.0, 'x coordinate must be between 0.0 and 1.0'),
      assert(y >= 0.0 && y <= 1.0, 'y coordinate must be between 0.0 and 1.0');
  
  Map<String, dynamic> toMap() {
    return {'x': x, 'y': y};
  }
  
  factory FocusPoint.fromMap(Map<String, dynamic> map) {
    return FocusPoint(
      (map['x'] as num).toDouble(),
      (map['y'] as num).toDouble(),
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FocusPoint &&
        (other.x - x).abs() < 0.001 &&
        (other.y - y).abs() < 0.001;
  }
  
  @override
  int get hashCode => Object.hash(x, y);
  
  @override
  String toString() => 'FocusPoint($x, $y)';
}

/// Exposure mode for camera control
enum ExposureMode {
  auto('auto'),
  manual('manual');
  
  const ExposureMode(this.value);
  final String value;
  
  static ExposureMode fromString(String value) {
    return ExposureMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => ExposureMode.auto,
    );
  }
}

/// Camera resolution preference
enum CameraResolution {
  low('low'),      // 480p
  medium('medium'), // 720p
  high('high'),    // 1080p
  ultra('ultra');  // 4K if supported
  
  const CameraResolution(this.value);
  final String value;
  
  static CameraResolution fromString(String value) {
    return CameraResolution.values.firstWhere(
      (res) => res.value == value,
      orElse: () => CameraResolution.medium,
    );
  }
}

/// Camera position preference
enum CameraPosition {
  back('back'),
  front('front');
  
  const CameraPosition(this.value);
  final String value;
  
  static CameraPosition fromString(String value) {
    return CameraPosition.values.firstWhere(
      (pos) => pos.value == value,
      orElse: () => CameraPosition.back,
    );
  }
}

/// White balance mode for camera control
enum WhiteBalanceMode {
  auto('auto'),
  daylight('daylight'),
  cloudy('cloudy'),
  tungsten('tungsten'),
  fluorescent('fluorescent');
  
  const WhiteBalanceMode(this.value);
  final String value;
  
  static WhiteBalanceMode fromString(String value) {
    return WhiteBalanceMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => WhiteBalanceMode.auto,
    );
  }
}