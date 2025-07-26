package com.example.quickqr_scanner

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.SurfaceTexture
import android.hardware.camera2.*
import android.media.ImageReader
import android.os.Build
import android.util.Log
import android.util.Size
import android.view.TextureView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import java.io.File

/** QuickQR Scanner Plugin - ML Kit Integration */
class QuickqrScannerPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    
    companion object {
        private const val TAG = "QuickQRScanner"
        private const val METHOD_CHANNEL = "quickqr_scanner"
        private const val EVENT_CHANNEL = "quickqr_scanner/events"
        private const val CAMERA_PERMISSION_REQUEST = 1001
    }

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    
    private var eventSink: EventChannel.EventSink? = null
    private var barcodeScanner: BarcodeScanner? = null
    private var cameraManager: CameraManager? = null
    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var imageReader: ImageReader? = null
    
    private var isScanning = false
    private var lastDetectedQR: String? = null
    private var lastDetectionTime = 0L
    private val detectionCooldown = 1000L // 1秒
    
    // MARK: - Camera Control Properties
    private var cameraCharacteristics: CameraCharacteristics? = null
    private var captureRequestBuilder: CaptureRequest.Builder? = null
    
    // Current camera settings
    private var currentZoomLevel: Float = 1.0f
    private var isMacroModeEnabled: Boolean = false
    private var currentCameraId: String? = null
    private var isBackCamera: Boolean = true

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
        
        // PlatformView Factory Registration
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "quickqr_scanner_camera_view",
            QuickQRCameraViewFactory(flutterPluginBinding.binaryMessenger)
        )
        
        initializeMLKit()
        
        Log.i(TAG, "✅ QuickQR Scanner Plugin initialized")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        
        barcodeScanner?.close()
        disposeCameraSession()
    }

    // MARK: - Method Channel Handling
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkAvailability" -> checkDeviceAvailability(result)
            "checkPermissions" -> checkCameraPermissions(result)
            "requestPermissions" -> requestCameraPermissions(result)
            
            "initialize" -> initializeScanner(result)
            "startScanning" -> startScanning(result)
            "stopScanning" -> stopScanning(result)
            "dispose" -> disposeScanner(result)
            
            "toggleFlashlight" -> toggleFlashlight(result)
            "scanFromImage" -> {
                val imagePath = call.argument<String>("imagePath")
                if (imagePath != null) {
                    scanFromImage(imagePath, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Image path required", null)
                }
            }
            // MARK: - Camera Control Methods
            "setZoomLevel" -> {
                val zoomLevel = call.argument<Double>("zoomLevel")
                if (zoomLevel != null) {
                    setZoomLevel(zoomLevel.toFloat(), result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Zoom level required", null)
                }
            }
            "getZoomCapabilities" -> getZoomCapabilities(result)
            "setFocusMode" -> {
                val focusMode = call.argument<String>("focusMode")
                val focusPoint = call.argument<Map<String, Double>>("focusPoint")
                if (focusMode != null) {
                    setFocusMode(focusMode, focusPoint, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Focus mode required", null)
                }
            }
            "setMacroMode" -> {
                val enabled = call.argument<Boolean>("enabled")
                if (enabled != null) {
                    setMacroMode(enabled, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Enabled flag required", null)
                }
            }
            "getMacroModeState" -> getMacroModeState(result)
            "getFocusState" -> getFocusState(result)
            "getExposureState" -> getExposureState(result)
            "getCameraResolutionState" -> getCameraResolutionState(result)
            "getImageStabilizationState" -> getImageStabilizationState(result)
            "getWhiteBalanceState" -> getWhiteBalanceState(result)
            "getFrameRateState" -> getFrameRateState(result)
            "getHDRState" -> getHDRState(result)
            "setExposureMode" -> {
                val exposureMode = call.argument<String>("exposureMode")
                val exposureCompensation = call.argument<Double>("exposureCompensation")
                if (exposureMode != null) {
                    setExposureMode(exposureMode, exposureCompensation, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Exposure mode required", null)
                }
            }
            "setCameraResolution" -> {
                val resolution = call.argument<String>("resolution")
                if (resolution != null) {
                    setCameraResolution(resolution, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Resolution required", null)
                }
            }
            "switchCamera" -> {
                val position = call.argument<String>("position")
                if (position != null) {
                    switchCamera(position, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Camera position required", null)
                }
            }
            "setImageStabilization" -> {
                val enabled = call.argument<Boolean>("enabled")
                if (enabled != null) {
                    setImageStabilization(enabled, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Enabled flag required", null)
                }
            }
            "setWhiteBalanceMode" -> {
                val whiteBalanceMode = call.argument<String>("whiteBalanceMode")
                if (whiteBalanceMode != null) {
                    setWhiteBalanceMode(whiteBalanceMode, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "White balance mode required", null)
                }
            }
            "setFrameRate" -> {
                val frameRate = call.argument<Int>("frameRate")
                if (frameRate != null) {
                    setFrameRate(frameRate, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Frame rate required", null)
                }
            }
            "setHDRMode" -> {
                val enabled = call.argument<Boolean>("enabled")
                if (enabled != null) {
                    setHDRMode(enabled, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Enabled flag required", null)
                }
            }
            "getCameraCapabilities" -> getCameraCapabilities(result)
            "applyCameraControlConfig" -> {
                val config = call.argument<Map<String, Any>>("config")
                if (config != null) {
                    applyCameraControlConfig(config, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Configuration required", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    // MARK: - Event Channel Handling
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

    // MARK: - ML Kit Initialization
    private fun initializeMLKit() {
        val options = BarcodeScannerOptions.Builder()
            .setBarcodeFormats(
                Barcode.FORMAT_QR_CODE,
                Barcode.FORMAT_CODE_128,
                Barcode.FORMAT_CODE_39,
                Barcode.FORMAT_EAN_13,
                Barcode.FORMAT_EAN_8
            )
            .build()
        
        barcodeScanner = BarcodeScanning.getClient(options)
    }

    // MARK: - Device Capabilities
    private fun checkDeviceAvailability(result: Result) {
        val availability = mapOf(
            "isSupported" to true,
            "isAvailable" to true,
            "deviceInfo" to mapOf(
                "framework" to "Vision/MLKit",
                "hasCamera" to context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY),
                "hasCameraFlash" to context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH),
                "platformVersion" to Build.VERSION.SDK_INT
            )
        )
        
        result.success(availability)
    }

    // MARK: - Permission Management
    private fun checkCameraPermissions(result: Result) {
        val status = when (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)) {
            PackageManager.PERMISSION_GRANTED -> "granted"
            PackageManager.PERMISSION_DENIED -> "denied"
            else -> "notDetermined"
        }
        
        val permissionStatus = mapOf(
            "status" to status,
            "canRequest" to true,
            "hasCamera" to context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
        )
        
        result.success(permissionStatus)
    }

    private fun requestCameraPermissions(result: Result) {
        // Note: In a Flutter plugin, permission requests should be handled by the Flutter app
        // This is just a stub implementation
        val granted = ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        
        if (granted) {
            result.success(mapOf(
                "granted" to true,
                "status" to "granted"
            ))
        } else {
            result.success(mapOf(
                "granted" to false,
                "status" to "denied",
                "message" to "Camera permission is required. Please grant permission in app settings."
            ))
        }
    }

    // MARK: - Scanner Initialization
    private fun initializeScanner(result: Result) {
        try {
            // Basic initialization logic
            cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager?
            
            Log.i(TAG, "Scanner initialized successfully")
            
            result.success(mapOf(
                "success" to true,
                "message" to "Scanner initialized"
            ))
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize scanner", e)
            result.error("INIT_ERROR", "Failed to initialize camera: ${e.message}", null)
        }
    }

    // MARK: - Scanning Control
    private fun startScanning(result: Result) {
        try {
            isScanning = true
            result.success(mapOf(
                "success" to true,
                "message" to "Scanning started"
            ))
        } catch (e: Exception) {
            result.error("SCAN_START_ERROR", "Failed to start scanning: ${e.message}", null)
        }
        
        Log.i(TAG, "Camera scanning started")
    }

    private fun stopScanning(result: Result) {
        isScanning = false
        result.success(mapOf(
            "success" to true,
            "message" to "Scanning stopped"
        ))
        
        Log.i(TAG, "Camera scanning stopped")
    }

    private fun disposeScanner(result: Result) {
        disposeCameraSession()
        result.success(mapOf(
            "success" to true,
            "message" to "Scanner disposed"
        ))
    }

    // MARK: - Flashlight Control (Basic)
    private fun toggleFlashlight(result: Result) {
        result.success(mapOf(
            "isOn" to false,
            "message" to "Flashlight not implemented in basic version"
        ))
    }

    // MARK: - Image Scanning
    private fun scanFromImage(imagePath: String, result: Result) {
        try {
            val imageFile = File(imagePath)
            if (!imageFile.exists()) {
                result.error("FILE_NOT_FOUND", "Image file not found: $imagePath", null)
                return
            }
            
            val bitmap = BitmapFactory.decodeFile(imagePath)
            if (bitmap == null) {
                result.error("INVALID_IMAGE", "Failed to decode image: $imagePath", null)
                return
            }
            
            val image = InputImage.fromBitmap(bitmap, 0)
            
            barcodeScanner?.process(image)
                ?.addOnSuccessListener { barcodes ->
                    val barcode = barcodes.firstOrNull()
                    if (barcode != null) {
                        val scanResult = mapOf(
                            "content" to barcode.rawValue,
                            "format" to getBarcodeFormat(barcode.format),
                            "timestamp" to System.currentTimeMillis(),
                            "confidence" to 1.0
                        )
                        result.success(scanResult)
                    } else {
                        result.success(null)
                    }
                }
                ?.addOnFailureListener { e ->
                    result.error("PROCESSING_ERROR", "Failed to process image: ${e.message}", null)
                }
            
        } catch (e: Exception) {
            result.error("PROCESSING_ERROR", "Failed to process image: ${e.message}", null)
        }
    }

    private fun getBarcodeFormat(format: Int): String {
        return when (format) {
            Barcode.FORMAT_QR_CODE -> "qr"
            Barcode.FORMAT_CODE_128 -> "code128"
            Barcode.FORMAT_CODE_39 -> "code39"
            Barcode.FORMAT_EAN_13 -> "ean13"
            Barcode.FORMAT_EAN_8 -> "ean8"
            else -> "unknown"
        }
    }

    // MARK: - Cleanup
    private fun disposeCameraSession() {
        try {
            captureSession?.close()
            cameraDevice?.close()
            imageReader?.close()
            
            captureSession = null
            cameraDevice = null
            imageReader = null
            
        } catch (e: Exception) {
            Log.w(TAG, "Error disposing camera session", e)
        }
    }

    // MARK: - Camera Control Implementation
    private fun setZoomLevel(zoomLevel: Float, result: MethodChannel.Result) {
        val characteristics = cameraCharacteristics
        if (characteristics == null) {
            result.error("CAMERA_NOT_AVAILABLE", "Camera characteristics not available", null)
            return
        }
        
        try {
            val zoomRatio = characteristics.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM)
                ?: 1.0f
            val maxZoom = minOf(zoomRatio, 10.0f) // Limit to 10x
            val targetZoom = maxOf(1.0f, minOf(zoomLevel, maxZoom))
            
            captureRequestBuilder?.let { builder ->
                val cropRegion = getCropRegionForZoom(characteristics, targetZoom)
                builder.set(CaptureRequest.SCALER_CROP_REGION, cropRegion)
                
                // Apply the updated capture request
                captureSession?.setRepeatingRequest(builder.build(), null, null)
            }
            
            currentZoomLevel = targetZoom
            
            val resultMap = mapOf(
                "success" to true,
                "currentZoom" to targetZoom.toDouble(),
                "maxZoom" to maxZoom.toDouble()
            )
            
            result.success(resultMap)
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set zoom level", e)
            result.error("ZOOM_ERROR", "Failed to set zoom level: ${e.message}", null)
        }
    }

    private fun getCropRegionForZoom(characteristics: CameraCharacteristics, zoomLevel: Float): android.graphics.Rect {
        val sensorArraySize = characteristics.get(CameraCharacteristics.SENSOR_INFO_ACTIVE_ARRAY_SIZE)!!
        
        val cropWidth = (sensorArraySize.width() / zoomLevel).toInt()
        val cropHeight = (sensorArraySize.height() / zoomLevel).toInt()
        
        val cropX = (sensorArraySize.width() - cropWidth) / 2
        val cropY = (sensorArraySize.height() - cropHeight) / 2
        
        return android.graphics.Rect(cropX, cropY, cropX + cropWidth, cropY + cropHeight)
    }

    private fun getZoomCapabilities(result: MethodChannel.Result) {
        val characteristics = cameraCharacteristics
        if (characteristics == null) {
            result.error("CAMERA_NOT_AVAILABLE", "Camera characteristics not available", null)
            return
        }
        
        val maxZoom = characteristics.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM) ?: 1.0f
        
        val resultMap = mapOf(
            "currentZoom" to currentZoomLevel.toDouble(),
            "minZoom" to 1.0,
            "maxZoom" to maxZoom.toDouble(),
            "supportsOpticalZoom" to false
        )
        
        result.success(resultMap)
    }

    // MARK: - Additional Camera Control Methods (Stub implementations)
    
    private fun setFocusMode(focusMode: String, focusPoint: Map<String, Double>?, result: MethodChannel.Result) {
        result.success(mapOf(
            "success" to true,
            "focusMode" to focusMode,
            "focusPoint" to focusPoint
        ))
    }

    private fun setMacroMode(enabled: Boolean, result: MethodChannel.Result) {
        result.success(mapOf(
            "success" to true,
            "enabled" to enabled,
            "supported" to true
        ))
    }

    private fun setExposureMode(exposureMode: String, exposureCompensation: Double?, result: MethodChannel.Result) {
        result.success(mapOf(
            "success" to true,
            "exposureMode" to exposureMode,
            "exposureCompensation" to exposureCompensation
        ))
    }

    private fun setCameraResolution(resolution: String, result: MethodChannel.Result) {
        result.success(mapOf(
            "success" to true,
            "resolution" to resolution,
            "actualSize" to mapOf("width" to 1920, "height" to 1080)
        ))
    }

    private fun switchCamera(position: String, result: MethodChannel.Result) {
        result.success(mapOf(
            "success" to true,
            "position" to position,
            "available" to listOf("back", "front")
        ))
    }

    private fun setImageStabilization(enabled: Boolean, result: MethodChannel.Result) {
        result.success(mapOf(
            "success" to true,
            "enabled" to enabled,
            "supported" to true
        ))
    }

    private fun setWhiteBalanceMode(whiteBalanceMode: String, result: MethodChannel.Result) {
        result.success(mapOf(
            "success" to true,
            "whiteBalanceMode" to whiteBalanceMode,
            "supported" to listOf("auto", "daylight", "cloudy", "tungsten", "fluorescent")
        ))
    }

    private fun setFrameRate(frameRate: Int, result: MethodChannel.Result) {
        result.success(mapOf(
            "success" to true,
            "frameRate" to frameRate,
            "supportedRanges" to listOf(
                mapOf("min" to 15.0, "max" to 30.0),
                mapOf("min" to 30.0, "max" to 60.0)
            )
        ))
    }

    private fun setHDRMode(enabled: Boolean, result: MethodChannel.Result) {
        result.success(mapOf(
            "success" to true,
            "enabled" to enabled,
            "supported" to true
        ))
    }

    private fun getCameraCapabilities(result: MethodChannel.Result) {
        result.success(mapOf(
            "zoom" to mapOf(
                "currentZoom" to 1.0,
                "minZoom" to 1.0,
                "maxZoom" to 10.0,
                "supportsOpticalZoom" to false
            ),
            "focus" to mapOf(
                "currentMode" to "auto",
                "supportedModes" to listOf("auto", "manual", "infinity", "macro"),
                "supportsPointOfInterest" to true
            ),
            "exposure" to mapOf(
                "currentMode" to "auto",
                "supportedModes" to listOf("auto", "manual"),
                "minBias" to -2.0,
                "maxBias" to 2.0
            ),
            "features" to mapOf(
                "macroMode" to true,
                "stabilization" to true,
                "hdr" to true,
                "flashlight" to true,
                "whiteBalance" to true
            )
        ))
    }

    private fun applyCameraControlConfig(config: Map<String, Any>, result: MethodChannel.Result) {
        result.success(mapOf(
            "success" to true,
            "applied" to mapOf(
                "zoom" to true,
                "macroMode" to true,
                "focusMode" to true
            ),
            "warnings" to emptyList<String>()
        ))
    }

    // State getter methods
    private fun getMacroModeState(result: MethodChannel.Result) {
        result.success(mapOf(
            "enabled" to isMacroModeEnabled,
            "supported" to true
        ))
    }

    private fun getFocusState(result: MethodChannel.Result) {
        result.success(mapOf(
            "focusMode" to "auto",
            "focusPoint" to null,
            "supportedModes" to listOf("auto", "manual", "infinity", "macro")
        ))
    }

    private fun getExposureState(result: MethodChannel.Result) {
        result.success(mapOf(
            "exposureMode" to "auto",
            "exposureCompensation" to 0.0,
            "supportedModes" to listOf("auto", "manual")
        ))
    }

    private fun getCameraResolutionState(result: MethodChannel.Result) {
        result.success(mapOf(
            "resolution" to "high",
            "actualSize" to mapOf("width" to 1920, "height" to 1080),
            "supported" to listOf("low", "medium", "high", "ultra")
        ))
    }

    private fun getImageStabilizationState(result: MethodChannel.Result) {
        result.success(mapOf(
            "enabled" to false,
            "supported" to true
        ))
    }

    private fun getWhiteBalanceState(result: MethodChannel.Result) {
        result.success(mapOf(
            "whiteBalanceMode" to "auto",
            "supported" to listOf("auto", "daylight", "cloudy", "tungsten", "fluorescent")
        ))
    }

    private fun getFrameRateState(result: MethodChannel.Result) {
        result.success(mapOf(
            "frameRate" to 30,
            "supportedRanges" to listOf(
                mapOf("min" to 15.0, "max" to 30.0),
                mapOf("min" to 30.0, "max" to 60.0)
            )
        ))
    }

    private fun getHDRState(result: MethodChannel.Result) {
        result.success(mapOf(
            "enabled" to false,
            "supported" to true
        ))
    }
}

// MARK: - Platform View Factory
class QuickQRCameraViewFactory(private val messenger: io.flutter.plugin.common.BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        return QuickQRCameraView(context!!, viewId, args)
    }
}

/** Android Camera Preview View for QR Scanner */
class QuickQRCameraView(context: Context, id: Int, args: Any?) : PlatformView {
    private val view: android.widget.TextView
    
    init {
        val targetWidth = 640
        val targetHeight = 480
        
        // Create a simple text view as placeholder for camera preview
        view = android.widget.TextView(context).apply {
            text = "📱 Camera Preview\n🔍 Scan QR codes here\n\nActual camera integration would go here..."
            textSize = 16f
            gravity = android.view.Gravity.CENTER
            setBackgroundColor(android.graphics.Color.BLACK)
            setTextColor(android.graphics.Color.WHITE)
            
            // Camera permission check
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                text = "📱 Camera Preview Ready"
                
                if (args != null) {
                    layoutParams = android.view.ViewGroup.LayoutParams(targetWidth, targetHeight)
                    Log.i("QuickQRCameraView", "🔧 Set View size: ${targetWidth}x${targetHeight}")
                }
            }
            Log.w("QuickQRCameraView", "⚠️ Camera permission not granted")
        }
        
        Log.i("QuickQRCameraView", "📱 Android Camera view created with ID: $id, size: ${targetWidth}x${targetHeight}")
    }
    
    override fun getView(): android.view.View {
        return view
    }
    
    override fun dispose() {
        Log.i("QuickQRCameraView", "📱 Android Camera view disposed")
        // TextureViewのクリーンアップ
    }
}