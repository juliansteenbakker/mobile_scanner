import AVFoundation
import Flutter
import MLKitVision
import MLKitBarcodeScanning

public class SwiftMobileScannerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let registry: FlutterTextureRegistry
    
    // Sink for publishing event changes
    var sink: FlutterEventSink!
    
    // Texture id of the camera preview
    var textureId: Int64!
    
    // Capture session of the camera
    var captureSession: AVCaptureSession!
    
    // The selected camera
    var device: AVCaptureDevice!
    
    // Image to be sent to the texture
    var latestBuffer: CVImageBuffer!
    
//    var analyzeMode: Int = 0
    var analyzing: Bool = false
    var position = AVCaptureDevice.Position.back
    
    var scanner = BarcodeScanner.barcodeScanner()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftMobileScannerPlugin(registrar.textures())
        
        let method = FlutterMethodChannel(name:
                                            "dev.steenbakker.mobile_scanner/scanner/method", binaryMessenger: registrar.messenger())
        let event = FlutterEventChannel(name:
                                            "dev.steenbakker.mobile_scanner/scanner/event", binaryMessenger: registrar.messenger())
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
        case "torch":
            toggleTorch(call, result)
//        case "analyze":
//            switchAnalyzeMode(call, result)
        case "stop":
            stop(result)
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
    
    // Gets called when a new image is added to the buffer
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        latestBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        registry.textureFrameAvailable(textureId)

//        switch analyzeMode {
//        case 1: // barcode
            if analyzing {
                return
            }
            analyzing = true
            let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            let image = VisionImage(image: buffer!.image)
            image.orientation = imageOrientation(
              deviceOrientation: UIDevice.current.orientation,
              defaultOrientation: .portrait
            )

            scanner.process(image) { [self] barcodes, error in
                if error == nil && barcodes != nil {
                    for barcode in barcodes! {
                        let event: [String: Any?] = ["name": "barcode", "data": barcode.data]
                        sink?(event)
                    }
                }
                analyzing = false
            }
//        default: // none
//            break
//        }
    }
    
    func imageOrientation(
          deviceOrientation: UIDeviceOrientation,
          defaultOrientation: UIDeviceOrientation
        ) -> UIImage.Orientation {
          switch deviceOrientation {
          case .portrait:
            return position == .front ? .leftMirrored : .right
          case .landscapeLeft:
            return position == .front ? .downMirrored : .up
          case .portraitUpsideDown:
            return position == .front ? .rightMirrored : .left
          case .landscapeRight:
            return position == .front ? .upMirrored : .down
          case .faceDown, .faceUp, .unknown:
            return .up
          @unknown default:
            return imageOrientation(deviceOrientation: defaultOrientation, defaultOrientation: .portrait)
            }
        }
    
    func checkPermission(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            result(0)
        case .authorized:
            result(1)
        default:
            result(2)
        }
    }
    
    func requestPermission(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { result($0) })
    }

    func start(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        if (device != nil) {
            result(FlutterError(code: "MobileScanner",
                                    message: "Called start() while already started!",
                                    details: nil))
            return
        }
        
        textureId = registry.register(self)
        captureSession = AVCaptureSession()
        
        let argReader = MapArgumentReader(call.arguments as? [String: Any])
        
//        let ratio: Int = argReader.int(key: "ratio")
        let torch: Bool = argReader.bool(key: "torch") ?? false
        let facing: Int = argReader.int(key: "facing") ?? 1
        let formats: Array = argReader.intArray(key: "formats") ?? []
        
        let formatList: NSMutableArray = []
        for index in formats {
            formatList.add(BarcodeFormat(rawValue: index))
        }
        
        if (formatList.count != 0) {
            let barcodeOptions = BarcodeScannerOptions(formats: formatList.firstObject as! BarcodeFormat)
            scanner = BarcodeScanner.barcodeScanner(options: barcodeOptions)
        }
        
        // Set the camera to use
        position = facing == 0 ? AVCaptureDevice.Position.front : .back
        
        // Open the camera device
        if #available(iOS 10.0, *) {
            device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices.first
        } else {
            device = AVCaptureDevice.devices(for: .video).filter({$0.position == position}).first
        }
        
        if (device == nil) {
            result(FlutterError(code: "MobileScanner",
                                    message: "No camera found or failed to open camera!",
                                    details: nil))
            return
        }
        
        // Enable the torch if parameter is set and torch is available
        if (device.hasTorch && device.isTorchAvailable) {
            do {
                try device.lockForConfiguration()
            device.torchMode = torch ? .on : .off
            device.unlockForConfiguration()
        } catch {
            error.throwNative(result)
            }
        }
        
        device.addObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode), options: .new, context: nil)
        captureSession.beginConfiguration()
        
        // Add device input
        do {
            let input = try AVCaptureDeviceInput(device: device)
            captureSession.addInput(input)
        } catch {
            error.throwNative(result)
        }
        captureSession.sessionPreset = AVCaptureSession.Preset.photo;
        // Add video output.
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        captureSession.addOutput(videoOutput)
        for connection in videoOutput.connections {
            connection.videoOrientation = .portrait
            if position == .front && connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        captureSession.commitConfiguration()
        captureSession.startRunning()
        let demensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
        let width = Double(demensions.height)
        let height = Double(demensions.width)
        let size = ["width": width, "height": height]
        let answer: [String : Any?] = ["textureId": textureId, "size": size, "torchable": device.hasTorch]
        result(answer)
    }
    
    func toggleTorch(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        if (device == nil) {
            result(FlutterError(code: "MobileScanner",
                                    message: "Called toggleTorch() while stopped!",
                                    details: nil))
            return
        }
        do {
            try device.lockForConfiguration()
            device.torchMode = call.arguments as! Int == 1 ? .on : .off
            device.unlockForConfiguration()
            result(nil)
        } catch {
            error.throwNative(result)
        }
    }
    
//    func switchAnalyzeMode(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
//        analyzeMode = call.arguments as! Int
//        result(nil)
//    }
    
    func analyzeImage(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let uiImage = UIImage(contentsOfFile: call.arguments as! String)
        
        if (uiImage == nil) {
            result(FlutterError(code: "MobileScanner",
                                    message: "No image found in analyzeImage!",
                                    details: nil))
            return
        }
        
        let image = VisionImage(image: uiImage!)
        image.orientation = imageOrientation(
          deviceOrientation: UIDevice.current.orientation,
          defaultOrientation: .portrait
        )
        
        var barcodeFound = false

        scanner.process(image) { [self] barcodes, error in
            if error == nil && barcodes != nil {
                for barcode in barcodes! {
                    barcodeFound = true
                    let event: [String: Any?] = ["name": "barcode", "data": barcode.data]
                    sink?(event)
                }
            } else if error != nil {
                result(FlutterError(code: "MobileScanner",
                                    message: error?.localizedDescription,
                                    details: "analyzeImage()"))
            }
            analyzing = false
            result(barcodeFound)
        }

    }
    
    func stop(_ result: FlutterResult) {
        if (device == nil) {
            result(FlutterError(code: "MobileScanner",
                                    message: "Called stop() while already stopped!",
                                    details: nil))
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
        registry.unregisterTexture(textureId)
        
//        analyzeMode = 0
        latestBuffer = nil
        captureSession = nil
        device = nil
        textureId = nil
        
        result(nil)
    }
    
    // Observer for torch state
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "torchMode":
            // off = 0; on = 1; auto = 2;
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
    
    func intArray(key: String) -> [Int]? {
      return args?[key] as? [Int]
    }
  
}
