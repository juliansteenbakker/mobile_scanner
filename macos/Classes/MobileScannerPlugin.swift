import AVFoundation
import FlutterMacOS
import Vision
import AppKit

public class MobileScannerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate {
    
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

    // optional window to limit scan search
    var scanWindow: CGRect?
    
    var detectionSpeed: DetectionSpeed = DetectionSpeed.noDuplicates
    
    
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
            updateScanWindow(call)
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
    
    var i = 0
    
    
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
        
        if ((detectionSpeed == DetectionSpeed.normal || detectionSpeed == DetectionSpeed.noDuplicates) && i > 10 || detectionSpeed == DetectionSpeed.unrestricted) {
            i = 0
            let imageRequestHandler = VNImageRequestHandler(
                cvPixelBuffer: latestBuffer,
                orientation: .right)
            
                do {
                  try imageRequestHandler.perform([VNDetectBarcodesRequest { (request, error) in
                      if error == nil {
                          if let results = request.results as? [VNBarcodeObservation] {
                                for barcode in results {
                                    if self.scanWindow != nil {
                                        let match = self.isbarCodeInScanWindow(self.scanWindow!, barcode, self.latestBuffer)
                                        if (!match) {
                                            continue
                                        }
                                    }

                                    let barcodeType = String(barcode.symbology.rawValue).replacingOccurrences(of: "VNBarcodeSymbology", with: "")
                                    let event: [String: Any?] = ["name": "barcodeMac", "data" : ["payload": barcode.payloadStringValue, "symbology": barcodeType]]
                                    self.sink?(event)

        //                                    if barcodeType == "QR" {
        //                                        let image = CIImage(image: source)
        //                                        image?.cropping(to: barcode.boundingBox)
        //                                        self.qrCodeDescriptor(qrCode: barcode, qrCodeImage: image!)
        //                                    }
                                      }
                          }
                      } else {
                          print(error!.localizedDescription)
                      }
                  }])
                } catch {
                  print(error)
                }
        } else {
            i+=1
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

    func updateScanWindow(_ call: FlutterMethodCall) {
        let argReader = MapArgumentReader(call.arguments as? [String: Any])
        let scanWindowData: Array? = argReader.floatArray(key: "rect")

        if (scanWindowData == nil) {
            return 
        }

        let minX = scanWindowData![0] 
        let minY = scanWindowData![1]

        let width = scanWindowData![2]  - minX
        let height = scanWindowData![3] - minY

        scanWindow = CGRect(x: minX, y: minY, width: width, height: height)
    }

    func isbarCodeInScanWindow(_ scanWindow: CGRect, _ barcode: VNBarcodeObservation, _ inputImage: CVImageBuffer) -> Bool {
       let size = CVImageBufferGetEncodedSize(inputImage)

        let imageWidth = size.width;
        let imageHeight = size.height;

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
        
//        let ratio: Int = argReader.int(key: "ratio")
        let torch: Bool = argReader.bool(key: "torch") ?? false
        let facing: Int = argReader.int(key: "facing") ?? 1
        let speed: Int = (call.arguments as! Dictionary<String, Any?>)["speed"] as? Int ?? 0
        
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
        }
        captureSession.sessionPreset = AVCaptureSession.Preset.photo;
        // Add video output.
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        captureSession.addOutput(videoOutput)
        for connection in videoOutput.connections {
//            connection.videoOrientation = .portrait
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

  func floatArray(key: String) -> [CGFloat]? {
    return args?[key] as? [CGFloat]
  }
  
}
