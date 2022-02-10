import AVFoundation
import Flutter
import MLKitVision
import MLKitBarcodeScanning

public class SwiftMobileScannerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftMobileScannerPlugin(registrar.textures())
        
        let method = FlutterMethodChannel(name: "dev.steenbakker.mobile_scanner/scanner/method", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: method)
        
        let event = FlutterEventChannel(name: "dev.steenbakker.mobile_scanner/scanner/event", binaryMessenger: registrar.messenger())
        event.setStreamHandler(instance)
    }
    
    let registry: FlutterTextureRegistry
    var sink: FlutterEventSink!
    var textureId: Int64!
    var captureSession: AVCaptureSession!
    var device: AVCaptureDevice!
    var latestBuffer: CVImageBuffer!
    var analyzeMode: Int
    var analyzing: Bool
    
    init(_ registry: FlutterTextureRegistry) {
        self.registry = registry
        analyzeMode = 0
        analyzing = false
        super.init()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "state":
            stateNative(call, result)
        case "request":
            requestNative(call, result)
        case "start":
            startNative(call, result)
        case "torch":
            torchNative(call, result)
        case "analyze":
            analyzeNative(call, result)
        case "stop":
            stopNative(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
    
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if latestBuffer == nil {
            return nil
        }
        return Unmanaged<CVPixelBuffer>.passRetained(latestBuffer)
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        latestBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        registry.textureFrameAvailable(textureId)
        
        switch analyzeMode {
        case 1: // barcode
            if analyzing {
                break
            }
            analyzing = true
            let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            let image = VisionImage(image: buffer!.image)
            let scanner = BarcodeScanner.barcodeScanner()
            scanner.process(image) { [self] barcodes, error in
                if error == nil && barcodes != nil {
                    for barcode in barcodes! {
                        let event: [String: Any?] = ["name": "barcode", "data": barcode.data]
                        sink?(event)
                    }
                }
                analyzing = false
            }
        default: // none
            break
        }
    }
    
    func stateNative(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
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
    
    func requestNative(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { result($0) })
    }
    
    func startNative(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        textureId = registry.register(self)
        captureSession = AVCaptureSession()
        let position = call.arguments as! Int == 0 ? AVCaptureDevice.Position.front : .back
        if #available(iOS 10.0, *) {
            device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices.first
        } else {
            device = AVCaptureDevice.devices(for: .video).filter({$0.position == position}).first
        }
        device.addObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode), options: .new, context: nil)
        captureSession.beginConfiguration()
        // Add device input.
        do {
            let input = try AVCaptureDeviceInput(device: device)
            captureSession.addInput(input)
        } catch {
            error.throwNative(result)
        }
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
    
    func torchNative(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        do {
            try device.lockForConfiguration()
            device.torchMode = call.arguments as! Int == 1 ? .on : .off
            device.unlockForConfiguration()
            result(nil)
        } catch {
            error.throwNative(result)
        }
    }
    
    func analyzeNative(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        analyzeMode = call.arguments as! Int
        result(nil)
    }
    
    func stopNative(_ result: FlutterResult) {
        captureSession.stopRunning()
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        device.removeObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode))
        registry.unregisterTexture(textureId)
        
        analyzeMode = 0
        latestBuffer = nil
        captureSession = nil
        device = nil
        textureId = nil
        
        result(nil)
    }
    
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
