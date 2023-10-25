import AVFoundation
import FlutterMacOS
import Vision
import AppKit
import VideoToolbox

public class MobileScannerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let registry: FlutterTextureRegistry
    
    // Sink for publishing event changes
    var sink: FlutterEventSink!

    // Texture id of the camera preview
    var textureId: Int64!

    // Capture session of the camera
    var captureSession: AVCaptureSession!

    // The selected camera
    weak var device: AVCaptureDevice!

    // Image to be sent to the texture
    var latestBuffer: CVImageBuffer!

    // optional window to limit scan search
    var scanWindow: CGRect?

    var detectionSpeed: DetectionSpeed = DetectionSpeed.noDuplicates

    var timeoutSeconds: Double = 0

    var symbologies:[VNBarcodeSymbology] = []
    
    //    var analyzeMode: Int = 0
    var analyzing: Bool = false
    var position = AVCaptureDevice.Position.back
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MobileScannerPlugin(registrar.textures)
        let method = FlutterMethodChannel(name:
                                            "dev.steenbakker.mobile_scanner/scanner/method", binaryMessenger: registrar.messenger)
        let event = FlutterEventChannel(name:
                                            "dev.steenbakker.mobile_scanner/scanner/event", binaryMessenger: registrar.messenger)
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
        case "updateScanWindow":
            updateScanWindow(call, result)
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
        // Ignore invalid textureId
        if textureId == nil {
            return
        }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer from sample buffer.")
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
                if(self!.latestBuffer == nil){
                    return
                }
                var cgImage: CGImage?
                VTCreateCGImageFromCVPixelBuffer(self!.latestBuffer, options: nil, imageOut: &cgImage)
                let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage!)
                do {
                    let barcodeRequest:VNDetectBarcodesRequest = VNDetectBarcodesRequest(completionHandler: { [weak self] (request, error) in
                        self?.imagesCurrentlyBeingProcessed = false
                        if error == nil {
                            if let results = request.results as? [VNBarcodeObservation] {
                                for barcode in results {
                                    if self?.scanWindow != nil && cgImage != nil {
                                        let match = self?.isBarCodeInScanWindow(self!.scanWindow!, barcode, cgImage!) ?? false
                                        if (!match) {
                                            continue
                                        }
                                    }

                                    DispatchQueue.main.async {
                                        self?.sink?(["name": "barcodeMac", "data" : ["payload": barcode.payloadStringValue, "symbology": barcode.symbology.toInt as Any?]] as [String : Any])
                                    }
                                    //                                   if barcodeType == "QR" {
                                    //                                        let image = CIImage(image: source)
                                    //                                        image?.cropping(to: barcode.boundingBox)
                                    //                                        self.qrCodeDescriptor(qrCode: barcode, qrCodeImage: image!)
                                    //                                    }
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self?.sink?(FlutterError(code: "MobileScanner", message: error?.localizedDescription, details: nil))
                            }
                        }
                    })
                    if(self?.symbologies.isEmpty == false){
                        // add the symbologies the user wishes to support
                        barcodeRequest.symbologies = self!.symbologies
                    }
                    try imageRequestHandler.perform([barcodeRequest])
                } catch let e {
                    DispatchQueue.main.async {
                        self?.sink?(FlutterError(code: "MobileScanner", message: e.localizedDescription, details: nil))
                    }
                }
            }
        }
    }
    
    func checkPermission(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        if #available(macOS 10.14, *) {
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
        if #available(macOS 10.14, *) {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { result($0) })
        } else {
            result(0)
        }
    }

    func updateScanWindow(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let argReader = MapArgumentReader(call.arguments as? [String: Any])
        let scanWindowData: Array? = argReader.floatArray(key: "rect")

        if (scanWindowData == nil) {
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
    
    func isBarCodeInScanWindow(_ scanWindow: CGRect, _ barcode: VNBarcodeObservation, _ inputImage: CGImage) -> Bool {
        let imageWidth = CGFloat(inputImage.width)
        let imageHeight = CGFloat(inputImage.height)

        let minX = scanWindow.minX * imageWidth
        let minY = scanWindow.minY * imageHeight
        let width = scanWindow.width * imageWidth
        let height = scanWindow.height * imageHeight

        let scaledScanWindow = CGRect(x: minX, y: minY, width: width, height: height)
        return scaledScanWindow.contains(barcode.boundingBox)
    }

    func isBarCodeInScanWindow(_ scanWindow: CGRect, _ barcode: VNBarcodeObservation, _ inputImage: CVImageBuffer) -> Bool {
        let size = CVImageBufferGetEncodedSize(inputImage)

        let imageWidth = size.width
        let imageHeight = size.height

        let minX = scanWindow.minX * imageWidth
        let minY = scanWindow.minY * imageHeight
        let width = scanWindow.width * imageWidth
        let height = scanWindow.height * imageHeight

        let scaledScanWindow = CGRect(x: minX, y: minY, width: width, height: height)
        return scaledScanWindow.contains(barcode.boundingBox)
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

        // let ratio: Int = argReader.int(key: "ratio")
        let torch:Bool = argReader.bool(key: "torch") ?? false
        let facing:Int = argReader.int(key: "facing") ?? 1
        let speed:Int = argReader.int(key: "speed") ?? 0
        let timeoutMs:Int = argReader.int(key: "timeout") ?? 0
        symbologies = argReader.toSymbology()

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
            result(FlutterError(code: "MobileScanner",
                                message: "No camera found or failed to open camera!",
                                details: nil))
            return
        }
        
        // Enable the torch if parameter is set and torch is available
        if (device.hasTorch) {
            do {
                try device.lockForConfiguration()
                device.torchMode = torch ? .on : .off
                device.unlockForConfiguration()
            } catch {
                result(FlutterError(code: error.localizedDescription, message: nil, details: nil))
                return
            }
        }
        
        device.addObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode), options: .new, context: nil)
        captureSession.beginConfiguration()
        
        // Add device input
        do {
            let input = try AVCaptureDeviceInput(device: device)
            captureSession.addInput(input)
        } catch {
            result(FlutterError(code: error.localizedDescription, message: nil, details: nil))
            return
        }
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        // Add video output.
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        captureSession.addOutput(videoOutput)
        for connection in videoOutput.connections {
            // connection.videoOrientation = .portrait
            if position == .front && connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        captureSession.commitConfiguration()
        captureSession.startRunning()
        let dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
        let size = ["width": Double(dimensions.width), "height": Double(dimensions.height)]
        let answer: [String : Any?] = ["textureId": textureId, "size": size, "torchable": device.hasTorch]
        result(answer)
    }
    
    func toggleTorch(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        if (device == nil) {
            result(nil)
            return
        }
        do {
            try device.lockForConfiguration()
            device.torchMode = call.arguments as! Int == 1 ? .on : .off
            device.unlockForConfiguration()
            result(nil)
        } catch {
            result(FlutterError(code: error.localizedDescription, message: nil, details: nil))
        }
    }

    //    func switchAnalyzeMode(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    //        analyzeMode = call.arguments as! Int
    //        result(nil)
    //    }

    func stop(_ result: FlutterResult) {
        if (device == nil) {
            result(nil)

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
            // off = 0 on = 1 auto = 2
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

extension VNBarcodeSymbology {
    static func fromInt(_ mapValue:Int) -> VNBarcodeSymbology? {
        if #available(macOS 12.0, *) {
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

    var toInt:Int? {
        if #available(macOS 12.0, *) {
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
