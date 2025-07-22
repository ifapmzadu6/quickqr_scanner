import Flutter
import UIKit
import Vision
import AVFoundation
import os.log

/// QuickQR Scanner Plugin - VisionKit Integration
@available(iOS 12.0, *)
@objc(QuickqrScannerPlugin)
public class QuickqrScannerPlugin: NSObject, FlutterPlugin {
    
    // MARK: - Properties
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var methodChannel: FlutterMethodChannel?
    private var eventSink: FlutterEventSink?
    private var isScanning = false
    private var lastDetectedQR: String?
    private var lastDetectionTime: Date = Date()
    
    // QRコード検出制御
    private let detectionCooldown: TimeInterval = 1.0
    private let visionQueue = DispatchQueue(label: "com.quickqr.vision", qos: .userInitiated)
    
    // MARK: - Flutter Plugin Registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Method Channel
        let channel = FlutterMethodChannel(name: "quickqr_scanner", binaryMessenger: registrar.messenger())
        let instance = QuickqrScannerPlugin()
        instance.methodChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Event Channel for QR results
        let eventChannel = FlutterEventChannel(name: "quickqr_scanner/events", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
        
        os_log("✅ QuickQR Scanner Plugin registered", log: OSLog.default, type: .info)
    }
    
    // MARK: - FlutterPlugin Implementation
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkAvailability":
            checkDeviceAvailability(result: result)
        case "checkPermissions":
            checkCameraPermissions(result: result)
        case "requestPermissions":
            requestCameraPermissions(result: result)
        case "initialize":
            initializeScanner(result: result)
        case "startScanning":
            startScanning(result: result)
        case "stopScanning":
            stopScanning(result: result)
        case "dispose":
            disposeScanner(result: result)
        case "toggleFlashlight":
            toggleFlashlight(result: result)
        case "scanFromImage":
            if let args = call.arguments as? [String: Any],
               let imagePath = args["imagePath"] as? String {
                scanFromImage(imagePath: imagePath, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Image path required", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Device Compatibility Check
    private func checkDeviceAvailability(result: @escaping FlutterResult) {
        let availability: [String: Any] = [
            "isSupported": true,
            "isAvailable": AVCaptureDevice.default(for: .video) != nil,
            "supportedTypes": ["qr", "code128", "code39", "ean13"],
            "deviceInfo": [
                "model": UIDevice.current.model,
                "systemVersion": UIDevice.current.systemVersion,
                "framework": "Vision Framework iOS 12+"
            ]
        ]
        result(availability)
    }
    
    // MARK: - Permission Management
    private func checkCameraPermissions(result: @escaping FlutterResult) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let statusString: String
        let canRequest: Bool
        
        switch authStatus {
        case .authorized:
            statusString = "granted"
            canRequest = false
        case .denied:
            statusString = "denied"
            canRequest = false
        case .notDetermined:
            statusString = "notDetermined"
            canRequest = true
        case .restricted:
            statusString = "restricted"
            canRequest = false
        @unknown default:
            statusString = "unknown"
            canRequest = false
        }
        
        let permissionStatus: [String: Any] = [
            "status": statusString,
            "canRequest": canRequest,
            "hasCamera": AVCaptureDevice.default(for: .video) != nil
        ]
        
        result(permissionStatus)
    }
    
    private func requestCameraPermissions(result: @escaping FlutterResult) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        if authStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    result([
                        "granted": granted,
                        "status": granted ? "granted" : "denied"
                    ])
                }
            }
        } else {
            result([
                "granted": authStatus == .authorized,
                "status": authStatus == .authorized ? "granted" : "denied",
                "alreadyDetermined": true
            ])
        }
    }
    
    // MARK: - Scanner Initialization
    private func initializeScanner(result: @escaping FlutterResult) {
        guard !isScanning else {
            result(FlutterError(code: "ALREADY_RUNNING", message: "Scanner is already running", details: nil))
            return
        }
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        guard authStatus == .authorized else {
            if authStatus == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        if granted {
                            self.setupCaptureSession(result: result)
                        } else {
                            result(FlutterError(code: "PERMISSION_DENIED", message: "Camera permission denied", details: nil))
                        }
                    }
                }
            } else {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Camera permission required", details: nil))
            }
            return
        }
        
        setupCaptureSession(result: result)
    }
    
    private func setupCaptureSession(result: @escaping FlutterResult) {
        visionQueue.async {
            do {
                let session = AVCaptureSession()
                session.sessionPreset = .high
                
                guard let videoDevice = AVCaptureDevice.default(for: .video) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "NO_CAMERA", message: "No camera device found", details: nil))
                    }
                    return
                }
                
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                
                guard session.canAddInput(videoInput) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "INPUT_ERROR", message: "Cannot add camera input", details: nil))
                    }
                    return
                }
                session.addInput(videoInput)
                
                let output = AVCaptureVideoDataOutput()
                output.setSampleBufferDelegate(self, queue: self.visionQueue)
                output.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                output.alwaysDiscardsLateVideoFrames = true
                
                guard session.canAddOutput(output) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "OUTPUT_ERROR", message: "Cannot add video output", details: nil))
                    }
                    return
                }
                session.addOutput(output)
                
                // Main thread for final setup
                DispatchQueue.main.async {
                    self.captureSession = session
                    self.videoOutput = output
                    
                    let initResult: [String: Any] = [
                        "success": true,
                        "framework": "Vision Framework iOS 12+",
                        "hasCamera": true
                    ]
                    
                    result(initResult)
                }
                
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "INIT_ERROR", message: "Failed to initialize camera: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    // MARK: - Scanning Control
    private func startScanning(result: @escaping FlutterResult) {
        guard let session = captureSession, !isScanning else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Scanner not initialized or already running", details: nil))
            return
        }
        
        visionQueue.async {
            session.startRunning()
            self.isScanning = true
            
            DispatchQueue.main.async {
                result(["success": true, "message": "Scanning started"])
            }
        }
    }
    
    private func stopScanning(result: @escaping FlutterResult) {
        guard let session = captureSession, isScanning else {
            result(["success": true, "message": "Scanner already stopped"])
            return
        }
        
        visionQueue.async {
            session.stopRunning()
            self.isScanning = false
            
            DispatchQueue.main.async {
                result(["success": true, "message": "Scanning stopped"])
            }
        }
    }
    
    private func disposeScanner(result: @escaping FlutterResult) {
        visionQueue.async {
            self.captureSession?.stopRunning()
            self.captureSession = nil
            self.videoOutput = nil
            self.isScanning = false
            
            DispatchQueue.main.async {
                result(["success": true, "message": "Scanner disposed"])
            }
        }
    }
    
    // MARK: - Flashlight Control
    private func toggleFlashlight(result: @escaping FlutterResult) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            result(FlutterError(code: "NO_FLASH", message: "Device does not have flashlight", details: nil))
            return
        }
        
        do {
            try device.lockForConfiguration()
            if device.torchMode == .off {
                try device.setTorchModeOn(level: 1.0)
                result(["isOn": true, "message": "Flashlight turned on"])
            } else {
                device.torchMode = .off
                result(["isOn": false, "message": "Flashlight turned off"])
            }
            device.unlockForConfiguration()
        } catch {
            result(FlutterError(code: "FLASH_ERROR", message: "Failed to toggle flashlight: \(error.localizedDescription)", details: nil))
        }
    }
    
    // MARK: - Image Scanning
    private func scanFromImage(imagePath: String, result: @escaping FlutterResult) {
        guard let image = UIImage(contentsOfFile: imagePath) else {
            result(FlutterError(code: "FILE_NOT_FOUND", message: "Could not load image from path: \(imagePath)", details: nil))
            return
        }
        
        guard let cgImage = image.cgImage else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Could not convert image to CGImage", details: nil))
            return
        }
        
        visionQueue.async {
            let request = VNDetectBarcodesRequest { request, error in
                if let error = error {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "SCAN_ERROR", message: "Vision request failed: \(error.localizedDescription)", details: nil))
                    }
                    return
                }
                
                guard let results = request.results as? [VNBarcodeObservation],
                      let firstResult = results.first,
                      let payloadString = firstResult.payloadStringValue,
                      !payloadString.isEmpty else {
                    DispatchQueue.main.async {
                        result(nil) // No QR code found
                    }
                    return
                }
                
                let scanResult: [String: Any] = [
                    "content": payloadString,
                    "format": self.barcodeTypeToString(firstResult.symbology),
                    "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                    "confidence": firstResult.confidence
                ]
                
                DispatchQueue.main.async {
                    result(scanResult)
                }
            }
            
            request.symbologies = [.qr, .code128, .code39, .code93, .ean8, .ean13, .upce]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PROCESSING_ERROR", message: "Failed to process image: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func barcodeTypeToString(_ symbology: VNBarcodeSymbology) -> String {
        switch symbology {
        case .qr: return "qr"
        case .code128: return "code128"
        case .code39: return "code39"
        case .code93: return "code93"
        case .ean8: return "ean8"
        case .ean13: return "ean13"
        case .upce: return "upce"
        default: return "unknown"
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
@available(iOS 12.0, *)
extension QuickqrScannerPlugin: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isScanning,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              Date().timeIntervalSince(lastDetectionTime) > detectionCooldown else {
            return
        }
        
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let self = self,
                  let results = request.results as? [VNBarcodeObservation],
                  !results.isEmpty else {
                return
            }
            
            for observation in results {
                guard let payloadString = observation.payloadStringValue,
                      !payloadString.isEmpty,
                      payloadString != self.lastDetectedQR else {
                    continue
                }
                
                self.lastDetectedQR = payloadString
                self.lastDetectionTime = Date()
                
                // Send result via event channel
                let scanResult: [String: Any] = [
                    "content": payloadString,
                    "format": self.barcodeTypeToString(observation.symbology),
                    "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                    "confidence": observation.confidence
                ]
                
                DispatchQueue.main.async {
                    self.eventSink?(scanResult)
                }
                
                break
            }
        }
        
        request.symbologies = [.qr, .code128, .code39, .code93, .ean8, .ean13, .upce]
        
        let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - FlutterStreamHandler
@available(iOS 12.0, *)
extension QuickqrScannerPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}