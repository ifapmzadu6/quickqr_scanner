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

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
        
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
        val hasCamera = context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
        
        val availability = mapOf(
            "isSupported" to true,
            "isAvailable" to hasCamera,
            "supportedTypes" to listOf("qr", "code128", "code39", "ean13", "ean8"),
            "deviceInfo" to mapOf(
                "model" to "${Build.MANUFACTURER} ${Build.MODEL}",
                "systemVersion" to "Android ${Build.VERSION.RELEASE}",
                "framework" to "ML Kit Android"
            )
        )
        
        result.success(availability)
    }

    // MARK: - Permission Management
    private fun checkCameraPermissions(result: Result) {
        val permission = ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
        val hasCamera = context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
        
        val statusString = when (permission) {
            PackageManager.PERMISSION_GRANTED -> "granted"
            else -> "denied"
        }
        
        val permissionStatus = mapOf(
            "status" to statusString,
            "canRequest" to (permission != PackageManager.PERMISSION_GRANTED),
            "hasCamera" to hasCamera
        )
        
        result.success(permissionStatus)
    }

    private fun requestCameraPermissions(result: Result) {
        val permission = ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
        
        if (permission == PackageManager.PERMISSION_GRANTED) {
            result.success(mapOf(
                "granted" to true,
                "status" to "granted",
                "alreadyDetermined" to true
            ))
        } else {
            // 実際のアプリでは ActivityCompat.requestPermissions() を使用
            // プラグインでは権限リクエストのUI表示が困難なため、基本実装として"denied"を返す
            result.success(mapOf(
                "granted" to false,
                "status" to "denied",
                "message" to "Camera permission is required. Please grant permission in app settings."
            ))
        }
    }

    // MARK: - Scanner Initialization
    private fun initializeScanner(result: Result) {
        if (isScanning) {
            result.error("ALREADY_RUNNING", "Scanner is already running", null)
            return
        }
        
        val permission = ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
        if (permission != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "Camera permission required", null)
            return
        }
        
        try {
            cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            
            val initResult = mapOf(
                "success" to true,
                "framework" to "ML Kit Android",
                "hasCamera" to context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
            )
            
            result.success(initResult)
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize scanner", e)
            result.error("INIT_ERROR", "Failed to initialize camera: ${e.message}", null)
        }
    }

    // MARK: - Scanning Control
    private fun startScanning(result: Result) {
        if (isScanning) {
            result.error("ALREADY_RUNNING", "Scanner is already running", null)
            return
        }
        
        if (cameraManager == null) {
            result.error("NOT_INITIALIZED", "Scanner not initialized", null)
            return
        }
        
        // 基本実装: カメラセッションの詳細は省略し、成功レスポンスのみ
        isScanning = true
        result.success(mapOf(
            "success" to true,
            "message" to "Scanning started (basic implementation)"
        ))
        
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
        isScanning = false
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
        val file = File(imagePath)
        if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "Could not load image from path: $imagePath", null)
            return
        }
        
        try {
            val bitmap = BitmapFactory.decodeFile(imagePath)
            if (bitmap == null) {
                result.error("INVALID_IMAGE", "Could not decode image", null)
                return
            }
            
            val image = InputImage.fromBitmap(bitmap, 0)
            
            barcodeScanner?.process(image)
                ?.addOnSuccessListener { barcodes ->
                    if (barcodes.isNotEmpty()) {
                        val barcode = barcodes.first()
                        val scanResult = mapOf(
                            "content" to (barcode.rawValue ?: ""),
                            "format" to getBarcodeFormat(barcode.format),
                            "timestamp" to System.currentTimeMillis(),
                            "confidence" to 1.0
                        )
                        result.success(scanResult)
                    } else {
                        result.success(null) // No QR code found
                    }
                }
                ?.addOnFailureListener { e ->
                    Log.e(TAG, "Image scanning failed", e)
                    result.error("SCAN_ERROR", "Failed to scan image: ${e.message}", null)
                }
            
        } catch (e: Exception) {
            Log.e(TAG, "Image processing error", e)
            result.error("PROCESSING_ERROR", "Failed to process image: ${e.message}", null)
        }
    }

    private fun getBarcodeFormat(format: Int): String {
        return when (format) {
            Barcode.FORMAT_QR_CODE -> "qr"
            Barcode.FORMAT_CODE_128 -> "code128"
            Barcode.FORMAT_CODE_39 -> "code39"
            Barcode.FORMAT_CODE_93 -> "code93"
            Barcode.FORMAT_EAN_8 -> "ean8"
            Barcode.FORMAT_EAN_13 -> "ean13"
            Barcode.FORMAT_UPC_E -> "upce"
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
}
