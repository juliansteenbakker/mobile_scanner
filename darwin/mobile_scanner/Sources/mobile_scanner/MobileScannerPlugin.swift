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
    
#if os(iOS)
    var deviceOrientation: UIDeviceOrientation = UIDeviceOrientation.unknown
#endif
    
    private var stopped: Bool {
        return device == nil || captureSession == nil
    }

    private var paused: Bool {
        return stopped && textureId != nil
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
#if os(iOS)
        let textures = registrar.textures()
        let messenger = registrar.messenger()
#else
        let textures = registrar.textures
        let messenger = registrar.messenger
#endif

        let instance = MobileScannerPlugin(textures)
        let method = FlutterMethodChannel(name:
                                            "dev.steenbakker.mobile_scanner/scanner/method", binaryMessenger: messenger)
        let event = FlutterEventChannel(name:
                                            "dev.steenbakker.mobile_scanner/scanner/event", binaryMessenger: messenger)

        registrar.addMethodCallDelegate(instance, channel: method)
        event.setStreamHandler(instance)
        
#if os(iOS)
        let orientationEvent = FlutterEventChannel(name:
                                            "dev.steenbakker.mobile_scanner/scanner/deviceOrientation", binaryMessenger: messenger)
        orientationEvent.setStreamHandler(DeviceOrientationStreamHandler(onOrientationChanged: instance.setDeviceOrientation))
#endif
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
        case "setFocus":
            setFocus(call, result)
        case "resetScale":
            resetScale(call, result)
        case "pause":
            pause(call, result)
        case "stop":
            stop(call, result)
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
                guard let self = self else { return }
                if self.latestBuffer == nil {
                    return
                }
                var cgImage: CGImage?
                VTCreateCGImageFromCVPixelBuffer(self.latestBuffer, options: nil, imageOut: &cgImage)
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
                    if let scanWindow = self?.scanWindow {
                        barcodeRequest.regionOfInterest = scanWindow
                    }

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
        
        let left = scanWindowData![0]
        let top = scanWindowData![1]
        let right = scanWindowData![2]
        let bottom = scanWindowData![3]
        
        scanWindow = CGRect(
            x: left,                  // Normalized x-position (left)
            y: 1.0 - bottom,          // Flip Y-axis since Vision uses a different coordinate system
            width: right - left,      // Width (difference between right and left)
            height: bottom - top      // Height (difference between bottom and top)
        )
        
        result(nil)
    }

    private func getVideoOrientation() -> AVCaptureVideoOrientation {
#if os(iOS)
        // Get the orientation from the window scene if available
        // When the app's orientation is fixed and the app orientation is actually different from the device orientation, it malfunctions.
        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let orientation = windowScene.interfaceOrientation
                switch orientation {
                case .portrait:
                    return .portrait
                case .portraitUpsideDown:
                    return .portraitUpsideDown
                case .landscapeLeft:
                    return .landscapeLeft
                case .landscapeRight:
                    return .landscapeRight
                default:
                    break
                }         
            }
        }

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

        textureId = textureId ?? registry.register(self)
        captureSession = AVCaptureSession()

        let argReader = MapArgumentReader(call.arguments as? [String: Any])

        let torch:Bool = argReader.bool(key: "torch") ?? false
        let facing:Int = argReader.int(key: "facing") ?? 1
        let speed:Int = argReader.int(key: "speed") ?? 0
        let timeoutMs:Int = argReader.int(key: "timeout") ?? 0
        let initialZoom: CGFloat = CGFloat(argReader.float(key: "initialZoom") ?? 1)
        symbologies = argReader.toSymbology()
        MobileScannerPlugin.returnImage = argReader.bool(key: "returnImage") ?? false

        timeoutSeconds = Double(timeoutMs) / 1000.0
        detectionSpeed = DetectionSpeed(rawValue: speed)!

        // Set the camera to use. In macOS only a front camera is available.
#if os(iOS)
        position = facing == 0 ? AVCaptureDevice.Position.front : .back
#else
        position = AVCaptureDevice.Position.front
#endif
        
        // Open the camera device
#if os(iOS)
        if #available(iOS 13.0, *) {
            device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: position).devices.first
        }
#else
        if #available(macOS 10.15, *) {
            device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices.first
        }
#endif
        
        if (device == nil) {
            device = AVCaptureDevice.devices(for: .video).filter({$0.position == position}).first
        }
        
        if (device == nil) {
            device = AVCaptureDevice.default(for: .video)
        }
        
        if (device == nil) {
            result(FlutterError(code: MobileScannerErrorCodes.NO_CAMERA_ERROR,
                                message: MobileScannerErrorCodes.NO_CAMERA_ERROR_MESSAGE,
                                details: nil))
            return
        }

        device.addObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode), options: .new, context: nil)
#if os(iOS)
        device.addObserver(self, forKeyPath: #keyPath(AVCaptureDevice.videoZoomFactor), options: [.new, .initial], context: nil)
#endif
        captureSession!.beginConfiguration()
        
        // Check the zoom factor at switching from ultra wide camera to wide camera.
        standardZoomFactor = initialZoom
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
            
            if (!(captureSession!.canAddInput(input))) {
                result(FlutterError(
                    code: MobileScannerErrorCodes.CAMERA_ERROR,
                    message: MobileScannerErrorCodes.CAMERA_ERROR_CAPTURE_SESSION_INPUT_OCCUPIED_MESSAGE,
                    details: nil))
                return
            }
            
            captureSession!.addInput(input)
        } catch {
            result(FlutterError(
                code: MobileScannerErrorCodes.CAMERA_ERROR,
                message: error.localizedDescription, details: nil))
            return
        }
        captureSession!.sessionPreset = AVCaptureSession.Preset.high

        // Add video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        captureSession!.addOutput(videoOutput)
        let deviceVideoOrientation = self.getVideoOrientation()
        

        // Adjust orientation for the video connection
        if let connection = videoOutput.connections.first {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = deviceVideoOrientation
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

                // Turn on the torch if requested.
                if (torch) {
                    self.turnTorchOn()
                }
                
                // Set the initial zoom factor
                do {
                    try self.setScaleInternal(initialZoom)
                } catch {
                    // Do nothing.
                }

#if os(iOS)
                // The height and width are swapped because the default video orientation for ios is landscape right, but mobile_scanner operates in portrait mode.
                // When mobile_scanner is opened in landscape mode, the Dart code automatically swaps the width and height parameters back to match the correct orientation.
                let size = ["width": Double(dimensions.height), "height": Double(dimensions.width)]
#else
                let size = ["width": Double(dimensions.width), "height": Double(dimensions.height)]
#endif
                // Return the result on the main thread after the session starts.
                let answer: [String : Any?]

                if let device = self.device {
                    let cameraDirection: Int? = switch(device.position) {
                        case .back: 1
                        case .unspecified: nil
                        case .front: 0
                        @unknown default: nil
                    }
                    
                    answer = [
                        "textureId": self.textureId,
                        "size": size,
                        "currentTorchState": device.hasTorch ? device.torchMode.rawValue : -1,
                        "cameraDirection": cameraDirection,
                        "initialDeviceOrientation": deviceVideoOrientation.toOrientationString
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
                // Limit to 1.0 scale
                device.videoZoomFactor = getSafeZoomFactor(scale: scale)

                device.unlockForConfiguration()
#endif
        } catch {
            throw MobileScannerError.zoomError(error)
        }

    }
    
    private func setFocus(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
                  let dx = args["dx"] as? CGFloat,
                  let dy = args["dy"] as? CGFloat else {
                result(FlutterError(code: MobileScannerErrorCodes.INVALID_FOCUS_POINT,
                                    message: MobileScannerErrorCodes.INVALID_FOCUS_POINT_MESSAGE,
                                    details: nil))
                return
            }
            let focusPoint = CGPoint(x: dx, y: dy)
        
        do {
            if (device == nil) {
                throw MobileScannerError.zoomWhenStopped
            }

    #if os(iOS)
                if device.isFocusPointOfInterestSupported {
                    do {
                        try device.lockForConfiguration()
                        device.focusPointOfInterest = focusPoint
                        device.focusMode = .autoFocus
                        device.unlockForConfiguration()
                    } catch {
                        throw MobileScannerError.zoomError(error)
                    }
                }
    #endif
        
            result(nil)
        } catch {
            result(FlutterError(code: MobileScannerErrorCodes.GENERIC_ERROR,
                                message: MobileScannerErrorCodes.GENERIC_ERROR_MESSAGE,
                                details: nil))
        }
    }

#if os(iOS)
    /// Set the device orientation if it differs from previous orientation
    func setDeviceOrientation(orientation: UIDeviceOrientation) {
        if (device == nil || deviceOrientation == orientation) {
            return
        }

        deviceOrientation = orientation
        updateOrientation(orientation: orientation)
    }

    /// Update the device orientation of the first open video output
    func updateOrientation(orientation: UIDeviceOrientation) {
        if let videoOutput = captureSession!.outputs.compactMap({ $0 as? AVCaptureVideoDataOutput }).first {
            for connection in videoOutput.connections {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = orientation.videoOrientation
                }
            }
        }
    }
    
#endif

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
    
    func getSafeZoomFactor(scale: CGFloat) -> CGFloat {
        var scaleToUse = scale
#if os(iOS)
        var actualScale = (scale * 4) + 1
        
        // Set a maximum zoom limit of 5x
        actualScale = min(5.0, actualScale)
        
        // Ensure it does not exceed the camera's max zoom capability
        scaleToUse = min(device.activeFormat.videoMaxZoomFactor, actualScale)
#endif
        return scaleToUse
    }
    
    func getScaleFromZoomFactor(actualScale: CGFloat) -> CGFloat {
        return (actualScale - 1) / 4
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

    func pause(_ call: FlutterMethodCall, _ result: FlutterResult) {
        let force = (call.arguments as? Bool) ?? false
        if (!force) {
            if (paused || stopped) {
                result(nil)

                return
            }
        }

        releaseCamera()

        result(nil)
    }

    func stop(_ call: FlutterMethodCall, _ result: FlutterResult) {
        let force = (call.arguments as? Bool) ?? false
        if (!paused && stopped && !force) {
            result(nil)

            return
        }
        releaseCamera()
        releaseTexture()

        result(nil)
    }

    private func releaseCamera() {
        guard let captureSession = captureSession else {
            return
        }

        guard let device = device else {
            return
        }

        captureSession.stopRunning()
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        device.removeObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode))
#if os(iOS)
        device.removeObserver(self, forKeyPath: #keyPath(AVCaptureDevice.videoZoomFactor))
#endif

        latestBuffer = nil
        self.captureSession = nil
        self.device = nil
    }

    private func releaseTexture() {
        if (textureId == nil) {
            return
        }

        registry.unregisterTexture(textureId)
        textureId = nil
    }

    func analyzeImage(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        // The iOS Simulator cannot use some of the GPU features that are required for the Vision API.
        // Thus analyzing images is not supported on the iOS Simulator.
        //
        // See https://forums.developer.apple.com/forums/thread/696714
#if os(iOS) && targetEnvironment(simulator)
        result(FlutterError(
            code: MobileScannerErrorCodes.UNSUPPORTED_OPERATION_ERROR,
            message: MobileScannerErrorCodes.ANALYZE_IMAGE_IOS_SIMULATOR_NOT_SUPPORTED_ERROR_MESSAGE,
            details: nil
        ))
        return
#endif

        let argReader = MapArgumentReader(call.arguments as? [String: Any])
        let symbologies:[VNBarcodeSymbology] = argReader.toSymbology()

        guard let filePath: String = argReader.string(key: "filePath") else {
            result(nil)
            return
        }

        let fileUrl = URL(fileURLWithPath: filePath)

        guard let ciImage = CIImage(contentsOf: fileUrl) else {
            result(FlutterError(
                code: MobileScannerErrorCodes.BARCODE_ERROR,
                message: MobileScannerErrorCodes.ANALYZE_IMAGE_NO_VALID_IMAGE_ERROR_MESSAGE,
                details: nil
            ))
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
                    DispatchQueue.main.async {
                        result([
                            "name": "barcode",
                            "data": [],
                        ])
                    }
                    return
                }

                if barcodes.isEmpty {
                    DispatchQueue.main.async {
                        result([
                            "name": "barcode",
                            "data": [],
                        ])
                    }
                    return
                }
                    
                DispatchQueue.main.async {
                    result([
                        "name": "barcode",
                        "data": barcodes.map({ $0.toMap(imageWidth: Int(ciImage.extent.width), imageHeight: Int(ciImage.extent.height), scanWindow: self.scanWindow) }),
                    ])
                }
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
        case #keyPath(AVCaptureDevice.torchMode):
            // Off = 0, On = 1, Auto = 2
            let state = change?[.newKey] as? Int
            let event: [String: Any?] = ["name": "torchState", "data": state]
            sink?(event)
#if os(iOS)
        case #keyPath(AVCaptureDevice.videoZoomFactor):
            if let zoomScale = change?[.newKey] as? CGFloat,
               let device = object as? AVCaptureDevice {
                
                let scale = getScaleFromZoomFactor(actualScale: zoomScale)

                let event: [String: Any?] = ["name": "zoomScaleState", "data":scale]
                sink?(event)
            }
#endif
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
    
    func float(key: String) -> Float? {
        return (args?[key] as? NSNumber)?.floatValue
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
        var rawBytes: FlutterStandardTypedData? = nil
        
        if #available(iOS 17.0, macOS 14.0, *) {
            if let payloadData = payloadData {
                rawBytes = FlutterStandardTypedData(bytes: payloadData)
            }
        }

        let data = [
            // Clockwise, starting from the top-left corner.
            "corners":  [
                ["x": topLeftX, "y": topLeftY],
                ["x": topRightX, "y": topRightY],
                ["x": bottomRightX, "y": bottomRightY],
                ["x": bottomLeftX, "y": bottomLeftY],
            ],
            "format": symbology.toInt ?? -1,
            "rawBytes": rawBytes,
            "rawValue": payloadStringValue,
            "displayValue": payloadStringValue,
            "size": [
                "width": width,
                "height": height,
            ],
        ] as [String : Any?]
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

extension AVCaptureVideoOrientation {
    var toOrientationString: String {
        switch self {
        case .portrait:
            return "PORTRAIT_UP"
        case .portraitUpsideDown:
            return "PORTRAIT_DOWN"
        case .landscapeLeft:
            return "LANDSCAPE_LEFT"
        case .landscapeRight:
            return "LANDSCAPE_RIGHT"
        default:
            return "PORTRAIT_UP"
        }
    }
}

#if os(iOS)
extension UIDeviceOrientation {
    var toOrientationString: String {
        switch self {
        case .portrait:
            return "PORTRAIT_UP"
        case .portraitUpsideDown:
            return "PORTRAIT_DOWN"
        case .landscapeLeft:
            return "LANDSCAPE_LEFT"
        case .landscapeRight:
            return "LANDSCAPE_RIGHT"
        case .faceUp:
            return "PORTRAIT_UP"
        case .faceDown:
            return "PORTRAIT_DOWN"
        default:
            return "PORTRAIT_UP"
        }
    }
    
    /// Converts UIDeviceOrientation to correct VideoOrientation
    var videoOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portrait:
            return .portrait
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
}
#endif
