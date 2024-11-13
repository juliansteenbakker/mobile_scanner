import AVFoundation
import Vision
import VideoToolbox

#if os(iOS)
  import Flutter
  import UIKit
  import MobileCoreServices
#else
  import AppKit
  import FlutterMacOS
#endif

public class MobileScannerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let registry: FlutterTextureRegistry
    
    // Sink for publishing event changes
    var sink: FlutterEventSink!

    // Texture id of the camera preview
    var textureId: Int64!

    // Capture session of the camera
    var captureSession: AVCaptureSession?

    // The selected camera
    weak var device: AVCaptureDevice!

    // Image to be sent to the texture
    var latestBuffer: CVImageBuffer!

    // optional window to limit scan search
    var scanWindow: CGRect?
    
    /// Whether to return the input image with the barcode event.
    /// This is static to avoid accessing `self` in the `VNDetectBarcodesRequest` callback.
    private static var returnImage: Bool = false

    var detectionSpeed: DetectionSpeed = DetectionSpeed.noDuplicates

    var timeoutSeconds: Double = 0

    var symbologies:[VNBarcodeSymbology] = []
    
    var position = AVCaptureDevice.Position.back
    
    var standardZoomFactor: CGFloat = 1
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let textures = registrar.textures()
        #else
        let textures = registrar.textures
        #endif
        
        #if os(iOS)
        let messenger = registrar.messenger()
        #else
        let messenger = registrar.messenger
        #endif
        
        let instance = MobileScannerPlugin(textures)
        let method = FlutterMethodChannel(name:
                                            "dev.steenbakker.mobile_scanner/scanner/method", binaryMessenger: messenger)
        let event = FlutterEventChannel(name:
                                            "dev.steenbakker.mobile_scanner/scanner/event", binaryMessenger: messenger)
        registrar.addMethodCallDelegate(instance, channel: method)
        event.setStreamHandler(instance)
    }
    
    init(_ registry: FlutterTextureRegistry) {
        self.registry = registry
        super.init()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "state":
            checkPermission(call, result)
        case "request":
            requestPermission(call, result)
        case "start":
            start(call, result)
        case "toggleTorch":
            toggleTorch(result)
        case "setScale":
            setScale(call, result)
        case "resetScale":
            resetScale(call, result)
        case "stop":
            stop(result)
        case "updateScanWindow":
            updateScanWindow(call, result)
        case "analyzeImage":
            analyzeImage(call, result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // FlutterStreamHandler
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }
    
    // FlutterStreamHandler
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
    
    // FlutterTexture
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if latestBuffer == nil {
            return nil
        }
        return Unmanaged<CVPixelBuffer>.passRetained(latestBuffer)
    }
    
    var nextScanTime = 0.0
    var imagesCurrentlyBeingProcessed = false
    
    // Gets called when a new image is added to the buffer
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Ignore invalid texture id.
        if textureId == nil {
            return
        }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        latestBuffer = imageBuffer
        registry.textureFrameAvailable(textureId)
        
        let currentTime = Date().timeIntervalSince1970
        let eligibleForScan = currentTime > nextScanTime && !imagesCurrentlyBeingProcessed
        if ((detectionSpeed == DetectionSpeed.normal || detectionSpeed == DetectionSpeed.noDuplicates) && eligibleForScan || detectionSpeed == DetectionSpeed.unrestricted) {
            nextScanTime = currentTime + timeoutSeconds
            imagesCurrentlyBeingProcessed = true
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                if self!.latestBuffer == nil {
                    return
                }
                var cgImage: CGImage?
                VTCreateCGImageFromCVPixelBuffer(self!.latestBuffer, options: nil, imageOut: &cgImage)
                let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage!)
                do {
                    let barcodeRequest: VNDetectBarcodesRequest = VNDetectBarcodesRequest(completionHandler: { [weak self] (request, error) in
                        self?.imagesCurrentlyBeingProcessed = false
                        
                        if error != nil {
                            DispatchQueue.main.async {
                                self?.sink?(FlutterError(
                                    code: MobileScannerErrorCodes.BARCODE_ERROR,
                                    message: error?.localizedDescription, details: nil))
                            }
                            return
                        }
                        
                        guard let results: [VNBarcodeObservation] = request.results as? [VNBarcodeObservation] else {
                            return
                        }
                        
                        if results.isEmpty {
                            return
                        }
                        
                        let barcodes: [VNBarcodeObservation] = results.compactMap({ barcode in
                            // If there is a scan window, check if the barcode is within said scan window.
//                            if self?.scanWindow != nil && cgImage != nil && !(self?.isBarcodeInsideScanWindow(barcodeObservation: barcode, imageSize: CGSize(width: cgImage!.width, height: cgImage!.height)) ?? false) {
//                                return nil
//                            }
//                            
                            return barcode
                        })
                        
                        DispatchQueue.main.async {
                            // If the image is nil, use zero as the size.
                            guard let image = cgImage else {
                                self?.sink?([
                                    "name": "barcode",
                                    "data": barcodes.map({ $0.toMap(imageWidth: 0, imageHeight: 0, scanWindow: nil)}),
                                ])
                                return
                            }
                            
                            // The image dimensions are always provided.
                            // The image bytes are only non-null when `returnImage` is true.
                            let imageData: [String: Any?] = [
                                "bytes": MobileScannerPlugin.returnImage ? FlutterStandardTypedData(bytes: image.jpegData(compressionQuality: 0.8)!) : nil,
                                "width": Double(image.width),
                                "height": Double(image.height),
                            ]
                            
                            self?.sink?([
                                "name": "barcode",
                                "data": barcodes.map({ $0.toMap(imageWidth: image.width, imageHeight: image.height, scanWindow: self?.scanWindow) }),
                                "image": imageData,
                            ])
                        }
                    })
                    
                    if self?.symbologies.isEmpty == false {
                        // Add the symbologies the user wishes to support.
                        barcodeRequest.symbologies = self!.symbologies
                    }
                    
                    // Set the region of interest to match scanWindow
//                    if let scanWindow = self?.scanWindow {
//                        barcodeRequest.regionOfInterest = scanWindow
//                    }
                    // Set the region of interest to match scanWindow
                    if let scanWindow = self?.scanWindow {
                        barcodeRequest.regionOfInterest = scanWindow
                    }
                    
                    
//                    !(self?.isBarcodeInsideScanWindow(barcodeObservation: barcode, imageSize: CGSize(width: cgImage!.width, height: cgImage!.height))
//                    if (self?.scanWindow != nil) {
//                        barcodeRequest.regionOfInterest = self!.scanWindow!
//                    }
                    

                    try imageRequestHandler.perform([barcodeRequest])
                } catch let error {
                    DispatchQueue.main.async {
                        self?.sink?(FlutterError(
                            code: MobileScannerErrorCodes.BARCODE_ERROR,
                            message: error.localizedDescription, details: nil))
                    }
                }
            }
        }
    }
    
    func checkPermission(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        if #available(iOS 12.0, macOS 10.14, *) {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .notDetermined:
                result(0)
            case .authorized:
                result(1)
            default:
                result(2)
            }
        } else {
            result(1)
        }
    }
    
    func requestPermission(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        if #available(iOS 12.0, macOS 10.14, *) {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { result($0) })
        } else {
            result(0)
        }
    }

    func updateScanWindow(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let argReader = MapArgumentReader(call.arguments as? [String: Any])
        let scanWindowData: Array? = argReader.floatArray(key: "rect")

        if (scanWindowData == nil) {
            scanWindow = nil
            result(nil)
            return
        }

        let minX = scanWindowData![0]
        let minY = scanWindowData![1]

        let width = scanWindowData![2]  - minX
        let height = scanWindowData![3] - minY

        scanWindow = CGRect(x: minX, y: minY, width: width, height: height)
        result(nil)
    }
    
    func isBarcodeInsideScanWindow(barcodeObservation: VNBarcodeObservation, imageSize: CGSize) -> Bool {
        let boundingBox = barcodeObservation.boundingBox
        
        // Adjust boundingBox by inverting the y-axis
        let adjustedBoundingBox = CGRect(
            x: boundingBox.minX,
            y: 1.0 - boundingBox.maxY,
            width: boundingBox.width,
            height: boundingBox.height
        )
        
        let intersects = scanWindow!.contains(adjustedBoundingBox)
        
        // Check if the adjusted bounding box intersects with or is within the scan window
        return intersects
    }

    
    private func getVideoOrientation() -> AVCaptureVideoOrientation {
#if os(iOS)
        var videoOrientation: AVCaptureVideoOrientation

        switch UIDevice.current.orientation {
        case .portrait:
            videoOrientation = .portrait
        case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            videoOrientation = .landscapeLeft
        case .landscapeRight:
            videoOrientation = .landscapeRight
        default:
            videoOrientation = .portrait
        }

        return videoOrientation
#else
        return .portrait
#endif
    }
    

    func start(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        if (device != nil || captureSession != nil) {
            result(FlutterError(code: MobileScannerErrorCodes.ALREADY_STARTED_ERROR,
                                message: MobileScannerErrorCodes.ALREADY_STARTED_ERROR_MESSAGE,
                                details: nil))
            return
        }

        textureId = registry.register(self)
        captureSession = AVCaptureSession()

        let argReader = MapArgumentReader(call.arguments as? [String: Any])

        let torch:Bool = argReader.bool(key: "torch") ?? false
        let facing:Int = argReader.int(key: "facing") ?? 1
        let speed:Int = argReader.int(key: "speed") ?? 0
        let timeoutMs:Int = argReader.int(key: "timeout") ?? 0
        symbologies = argReader.toSymbology()
        MobileScannerPlugin.returnImage = argReader.bool(key: "returnImage") ?? false

        timeoutSeconds = Double(timeoutMs) / 1000.0
        detectionSpeed = DetectionSpeed(rawValue: speed)!

        // Set the camera to use
        position = facing == 0 ? AVCaptureDevice.Position.front : .back
        
        // Open the camera device
        if #available(macOS 10.15, *) {
            device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices.first
        } else {
            device = AVCaptureDevice.devices(for: .video).filter({$0.position == position}).first
        }
        
        if (device == nil) {
            result(FlutterError(code: MobileScannerErrorCodes.NO_CAMERA_ERROR,
                                message: MobileScannerErrorCodes.NO_CAMERA_ERROR_MESSAGE,
                                details: nil))
            return
        }
        
        device.addObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode), options: .new, context: nil)
        captureSession!.beginConfiguration()
        
        // Check the zoom factor at switching from ultra wide camera to wide camera.
        standardZoomFactor = 1
        #if os(iOS)
        if #available(iOS 13.0, *) {
            for (index, actualDevice) in device.constituentDevices.enumerated() {
                if (actualDevice.deviceType != .builtInUltraWideCamera) {
                    if index > 0 && index <= device.virtualDeviceSwitchOverVideoZoomFactors.count {
                        standardZoomFactor = CGFloat(truncating: device.virtualDeviceSwitchOverVideoZoomFactors[index - 1])
                    }
                    break
                }
            }
        }
        #endif
        
        // Add device input
        do {
            let input = try AVCaptureDeviceInput(device: device)
            captureSession!.addInput(input)
        } catch {
            result(FlutterError(
                code: MobileScannerErrorCodes.CAMERA_ERROR,
                message: error.localizedDescription, details: nil))
            return
        }
        captureSession!.sessionPreset = AVCaptureSession.Preset.photo
        
        // Add video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        captureSession!.addOutput(videoOutput)
        let orientation = self.getVideoOrientation()

        // Adjust orientation for the video connection
        if let connection = videoOutput.connections.first {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = orientation
            }
            
            if position == .front && connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        
        captureSession!.commitConfiguration()

        // Move startRunning to a background thread to avoid blocking the main UI thread.
        DispatchQueue.global(qos: .background).async {
            self.captureSession!.startRunning()

            DispatchQueue.main.async {
                let dimensions: CMVideoDimensions
                
                if let device = self.device {
                    dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
                } else {
                    dimensions = CMVideoDimensions()
                }
                
                // Return the result on the main thread after the session starts.
                var width = Double(dimensions.width)
                var height = Double(dimensions.height)
                
#if os(iOS)
                // Swap width and height if the image is in portrait mode
                if orientation == AVCaptureVideoOrientation.portrait || orientation == AVCaptureVideoOrientation.portraitUpsideDown {
                    let temp = width
                    width = height
                    height = temp
                }
#endif
                
                // Turn on the torch if requested.
                if (torch) {
                    self.turnTorchOn()
                }

                let size = ["width": width, "height": height]
                
                let answer: [String : Any?]
                
                if let device = self.device {
                    answer = [
                        "textureId": self.textureId,
                        "size": size,
                        "currentTorchState": device.hasTorch ? device.torchMode.rawValue : -1,
                    ]
                } else {
                    answer = [
                        "textureId": self.textureId,
                        "size": size,
                        "currentTorchState": -1,
                    ]
                }
                
                result(answer)
            }
        }
    }
    
    /// Turn the torch on.
    private func turnTorchOn() {
        guard let device = self.device else {
            return
        }
        
        if (!device.hasTorch || !device.isTorchModeSupported(.on) || device.torchMode == .on) {
            return
        }
        
        if #available(macOS 15.0, *) {
            if(!device.isTorchAvailable) {
                return
            }
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = .on
            device.unlockForConfiguration()
        } catch(_) {
            // Do nothing.
        }
    }
    
    /// Sets the zoomScale.
    private func setScale(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let scale = call.arguments as? CGFloat
        if (scale == nil) {
            result(FlutterError(code: MobileScannerErrorCodes.GENERIC_ERROR,
                                message: MobileScannerErrorCodes.INVALID_ZOOM_SCALE_ERROR_MESSAGE,
                                details: "The invalid zoom scale was nil."))
            return
        }
        do {
            try setScaleInternal(scale!)
            result(nil)
        } catch MobileScannerError.zoomWhenStopped {
            result(FlutterError(code: MobileScannerErrorCodes.SET_SCALE_WHEN_STOPPED_ERROR,
                                message: MobileScannerErrorCodes.SET_SCALE_WHEN_STOPPED_ERROR_MESSAGE,
                                details: nil))
        } catch MobileScannerError.zoomError(let error) {
            result(FlutterError(code: MobileScannerErrorCodes.GENERIC_ERROR,
                                message: error.localizedDescription,
                                details: nil))
        } catch {
            result(FlutterError(code: MobileScannerErrorCodes.GENERIC_ERROR,
                                message: MobileScannerErrorCodes.GENERIC_ERROR_MESSAGE,
                                details: nil))
        }
    }

    /// Reset the zoomScale.
    private func resetScale(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        do {
            try resetScaleInternal()
            result(nil)
        } catch MobileScannerError.zoomWhenStopped {
            result(FlutterError(code: MobileScannerErrorCodes.SET_SCALE_WHEN_STOPPED_ERROR,
                                message: MobileScannerErrorCodes.SET_SCALE_WHEN_STOPPED_ERROR_MESSAGE,
                                details: nil))
        } catch MobileScannerError.zoomError(let error) {
            result(FlutterError(code: MobileScannerErrorCodes.GENERIC_ERROR,
                                message: error.localizedDescription,
                                details: nil))
        } catch {
            result(FlutterError(code: MobileScannerErrorCodes.GENERIC_ERROR,
                                message: MobileScannerErrorCodes.GENERIC_ERROR_MESSAGE,
                                details: nil))
        }
    }
    
    /// Set the zoom factor of the camera
    func setScaleInternal(_ scale: CGFloat) throws {
        if (device == nil) {
            throw MobileScannerError.zoomWhenStopped
        }
        
        do {
            #if os(iOS)
                try device.lockForConfiguration()
                let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
                
                var actualScale = (scale * 4) + 1
                
                // Set maximum zoomrate of 5x
                actualScale = min(5.0, actualScale)
                
                // Limit to max rate of camera
                actualScale = min(maxZoomFactor, actualScale)
                
                // Limit to 1.0 scale
                device.videoZoomFactor = actualScale

                device.unlockForConfiguration()
            #endif
        } catch {
            throw MobileScannerError.zoomError(error)
        }
        
    }

    /// Reset the zoom factor of the camera
    func resetScaleInternal() throws {
        if (device == nil) {
            throw MobileScannerError.zoomWhenStopped
        }

        do {
            #if os(iOS)
                try device.lockForConfiguration()
                device.videoZoomFactor = standardZoomFactor
                device.unlockForConfiguration()
            #endif
        } catch {
            throw MobileScannerError.zoomError(error)
        }
    }
    
    private func toggleTorch(_ result: @escaping FlutterResult) {
        guard let device = self.device else {
            result(nil)
            return
        }
        
        if (!device.hasTorch) {
            result(nil)
            return
        }
        
        if #available(macOS 15.0, *) {
            if(!device.isTorchAvailable) {
                result(nil)
                return
            }
        }
        
        var newTorchMode: AVCaptureDevice.TorchMode = device.torchMode
        
        switch(device.torchMode) {
        case AVCaptureDevice.TorchMode.auto:
            if #available(macOS 10.15, *) {
                newTorchMode = device.isTorchActive ? AVCaptureDevice.TorchMode.off : AVCaptureDevice.TorchMode.on
            }
            break;
        case AVCaptureDevice.TorchMode.off:
            newTorchMode = AVCaptureDevice.TorchMode.on
            break;
        case AVCaptureDevice.TorchMode.on:
            newTorchMode = AVCaptureDevice.TorchMode.off
            break;
        default:
            result(nil)
            return;
        }
        
        if (!device.isTorchModeSupported(newTorchMode) || device.torchMode == newTorchMode) {
            result(nil)
            return;
        }

        do {
            try device.lockForConfiguration()
            device.torchMode = newTorchMode
            device.unlockForConfiguration()
        } catch(_) {
            // Do nothing.
        }
        
        result(nil)
    }

    func stop(_ result: FlutterResult) {
        if (device == nil || captureSession == nil) {
            result(nil)

            return
        }
        captureSession!.stopRunning()
        for input in captureSession!.inputs {
            captureSession!.removeInput(input)
        }
        for output in captureSession!.outputs {
            captureSession!.removeOutput(output)
        }
        device.removeObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode))
        registry.unregisterTexture(textureId)
        
        latestBuffer = nil
        captureSession = nil
        device = nil
        textureId = nil
        
        result(nil)
    }
    
    func analyzeImage(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let argReader = MapArgumentReader(call.arguments as? [String: Any])
        let symbologies:[VNBarcodeSymbology] = argReader.toSymbology()
        
        guard let filePath: String = argReader.string(key: "filePath") else {
            result(nil)
            return
        }
        
        let fileUrl = URL(fileURLWithPath: filePath)
        
        guard let ciImage = CIImage(contentsOf: fileUrl) else {
            result(nil)
            return
        }
        
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: CGImagePropertyOrientation.up, options: [:])
        
        do {
            let barcodeRequest: VNDetectBarcodesRequest = VNDetectBarcodesRequest(
                completionHandler: { [] (request, error) in
                    
                if error != nil {
                    DispatchQueue.main.async {
                        result(FlutterError(
                            code: MobileScannerErrorCodes.BARCODE_ERROR,
                            message: error?.localizedDescription, details: nil))
                    }
                    return
                }
                    
                guard let barcodes: [VNBarcodeObservation] = request.results as? [VNBarcodeObservation] else {
                    return
                }
                    
                if barcodes.isEmpty {
                    return
                }
                    
                result([
                    "name": "barcode",
                    "data": barcodes.map({ $0.toMap(imageWidth: Int(ciImage.extent.width), imageHeight: Int(ciImage.extent.height), scanWindow: self.scanWindow) }),
                ])
            })
            
            if !symbologies.isEmpty {
                // Add the symbologies the user wishes to support.
                barcodeRequest.symbologies = symbologies
            }
            
            try imageRequestHandler.perform([barcodeRequest])
        } catch let error {
            DispatchQueue.main.async {
                result(FlutterError(
                    code: MobileScannerErrorCodes.BARCODE_ERROR,
                    message: error.localizedDescription, details: nil))
            }
        }
    }
    
    // Observer for torch state
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "torchMode":
            // Off = 0, On = 1, Auto = 2
            let state = change?[.newKey] as? Int
            let event: [String: Any?] = ["name": "torchState", "data": state]
            sink?(event)
        default:
            break
        }
    }
}

class MapArgumentReader {
    let args: [String: Any]?

    init(_ args: [String: Any]?) {
        self.args = args
    }

    func string(key: String) -> String? {
        return args?[key] as? String
    }

    func int(key: String) -> Int? {
        return (args?[key] as? NSNumber)?.intValue
    }

    func bool(key: String) -> Bool? {
        return (args?[key] as? NSNumber)?.boolValue
    }

    func stringArray(key: String) -> [String]? {
        return args?[key] as? [String]
    }

    func toSymbology() -> [VNBarcodeSymbology] {
        guard let syms:[Int] = args?["formats"] as? [Int] else {
            return []
        }
        if(syms.contains(0)){
            return []
        }
        var barcodeFormats:[VNBarcodeSymbology] = []
        syms.forEach { id in
            if let bc:VNBarcodeSymbology = VNBarcodeSymbology.fromInt(id) {
                barcodeFormats.append(bc)
            }
        }
        return barcodeFormats
    }

    func floatArray(key: String) -> [CGFloat]? {
        return args?[key] as? [CGFloat]
    }

}

extension CGImage {
    public func jpegData(compressionQuality: CGFloat) -> Data? {
        let mutableData = CFDataCreateMutable(nil, 0)
        
        let formatHint: CFString
        
        if #available(iOS 14.0, macOS 11.0, *) {
            formatHint = UTType.jpeg.identifier as CFString
        } else {
            formatHint = kUTTypeJPEG
        }
        
        guard let destination = CGImageDestinationCreateWithData(mutableData!, formatHint, 1, nil) else {
            return nil
        }
        
        let options: NSDictionary = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality,
        ]
        
        CGImageDestinationAddImage(destination, self, options)
        
        if !CGImageDestinationFinalize(destination) {
            return nil
        }
        
        return mutableData as Data?
    }
}

extension VNBarcodeObservation {
    private func distanceBetween(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
    }
    
    /// Map this `VNBarcodeObservation` to a dictionary.
    ///
    /// The `imageWidth` and `imageHeight` indicate the width and height of the input image that contains this observation.
    public func toMap(imageWidth: Int, imageHeight: Int, scanWindow: CGRect?) -> [String: Any?] {
        
        // Calculate adjusted points based on whether scanWindow is set
        let adjustedTopLeft: CGPoint
        let adjustedTopRight: CGPoint
        let adjustedBottomRight: CGPoint
        let adjustedBottomLeft: CGPoint
        
        if let scanWindow = scanWindow {
            // When a scanWindow is set, adjust the barcode coordinates to the full image
            func adjustPoint(_ point: CGPoint) -> CGPoint {
                let x = scanWindow.minX + point.x * scanWindow.width
                let y = scanWindow.minY + point.y * scanWindow.height
                return CGPoint(x: x, y: y)
            }
            
            adjustedTopLeft = adjustPoint(topLeft)
            adjustedTopRight = adjustPoint(topRight)
            adjustedBottomRight = adjustPoint(bottomRight)
            adjustedBottomLeft = adjustPoint(bottomLeft)
        } else {
            // If no scanWindow, use original points (already normalized to the full image)
            adjustedTopLeft = topLeft
            adjustedTopRight = topRight
            adjustedBottomRight = bottomRight
            adjustedBottomLeft = bottomLeft
        }
        
        // Convert adjusted points from normalized coordinates to image pixel coordinates
        let topLeftX = adjustedTopLeft.x * CGFloat(imageWidth)
        let topRightX = adjustedTopRight.x * CGFloat(imageWidth)
        let bottomRightX = adjustedBottomRight.x * CGFloat(imageWidth)
        let bottomLeftX = adjustedBottomLeft.x * CGFloat(imageWidth)
        let topLeftY = (1 - adjustedTopLeft.y) * CGFloat(imageHeight)
        let topRightY = (1 - adjustedTopRight.y) * CGFloat(imageHeight)
        let bottomRightY = (1 - adjustedBottomRight.y) * CGFloat(imageHeight)
        let bottomLeftY = (1 - adjustedBottomLeft.y) * CGFloat(imageHeight)
        
        // Calculate the width and height of the barcode based on adjusted coordinates
        let width = distanceBetween(adjustedTopLeft, adjustedTopRight) * CGFloat(imageWidth)
        let height = distanceBetween(adjustedTopLeft, adjustedBottomLeft) * CGFloat(imageHeight)
        
        let data = [
            // Clockwise, starting from the top-left corner.
            "corners":  [
                ["x": topLeftX, "y": topLeftY],
                ["x": topRightX, "y": topRightY],
                ["x": bottomRightX, "y": bottomRightY],
                ["x": bottomLeftX, "y": bottomLeftY],
            ],
            "format": symbology.toInt ?? -1,
            "rawValue": payloadStringValue ?? "",
            "displayValue": payloadStringValue ?? "",
            "size": [
                "width": width,
                "height": height,
            ],
        ] as [String : Any]
        return data
    }
}

extension VNBarcodeSymbology {
    static func fromInt(_ mapValue:Int) -> VNBarcodeSymbology? {
        if #available(iOS 15.0, macOS 12.0, *) {
            if(mapValue == 8){
                return VNBarcodeSymbology.codabar
            }
        }
        switch(mapValue){
        case 1:
            return VNBarcodeSymbology.code128
        case 2:
            return VNBarcodeSymbology.code39
        case 4:
            return VNBarcodeSymbology.code93
        case 16:
            return VNBarcodeSymbology.dataMatrix
        case 32:
            return VNBarcodeSymbology.ean13
        case 64:
            return VNBarcodeSymbology.ean8
        case 128:
            return VNBarcodeSymbology.itf14
        case 256:
            return VNBarcodeSymbology.qr
        case 1024:
            return VNBarcodeSymbology.upce
        case 2048:
            return VNBarcodeSymbology.pdf417
        case 4096:
            return VNBarcodeSymbology.aztec
        default:
            return nil
        }
    }

    var toInt: Int? {
        if #available(iOS 15.0, macOS 12.0, *) {
            if(self == VNBarcodeSymbology.codabar){
                return 8
            }
        }
        switch(self){
        case VNBarcodeSymbology.code128:
            return 1
        case VNBarcodeSymbology.code39:
            return 2
        case VNBarcodeSymbology.code93:
            return 4
        case VNBarcodeSymbology.dataMatrix:
            return 16
        case VNBarcodeSymbology.ean13:
            return 32
        case VNBarcodeSymbology.ean8:
            return 64
        case VNBarcodeSymbology.itf14:
            return 128
        case VNBarcodeSymbology.qr:
            return 256
        case VNBarcodeSymbology.upce:
            return 1024
        case VNBarcodeSymbology.pdf417:
            return 2048
        case VNBarcodeSymbology.aztec:
            return 4096
        default:
            return -1
        }
    }
}
