import Flutter
import MLKitVision
import MLKitBarcodeScanning
import AVFoundation

public class SwiftMobileScannerPlugin: NSObject, FlutterPlugin {
    
    /// The mobile scanner object that handles all logic
    private let mobileScanner: MobileScanner
    
    /// The handler sends all information via an event channel back to Flutter
    private let barcodeHandler: BarcodeHandler
    
    init(barcodeHandler: BarcodeHandler, registry: FlutterTextureRegistry) {
        self.mobileScanner = MobileScanner(registry: registry, mobileScannerCallback: { barcodes, error, image in
            if barcodes != nil {
                let barcodesMap = barcodes!.map { barcode in
                    return barcode.data
                }
                if (!barcodesMap.isEmpty) {
                    barcodeHandler.publishEvent(["name": "barcode", "data": barcodesMap, "image": FlutterStandardTypedData(bytes: image.jpegData(compressionQuality: 0.8)!)])
                }
            } else if (error != nil){
                barcodeHandler.publishEvent(["name": "error", "data": error!.localizedDescription])
            }
        })
        self.barcodeHandler = barcodeHandler
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftMobileScannerPlugin(barcodeHandler: BarcodeHandler(registrar: registrar), registry: registrar.textures())
        let methodChannel = FlutterMethodChannel(name:
                                                    "dev.steenbakker.mobile_scanner/scanner/method", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "state":
            result(mobileScanner.checkPermission())
        case "request":
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { result($0) })
        case "start":
            start(call, result)
        case "stop":
            stop(result)
        case "torch":
            toggleTorch(call, result)
        case "analyzeImage":
            analyzeImage(call, result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// Parses all parameters and starts the mobileScanner
    private func start(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let torch: Bool = (call.arguments as! Dictionary<String, Any?>)["torch"] as? Bool ?? false
        let facing: Int = (call.arguments as! Dictionary<String, Any?>)["facing"] as? Int ?? 1
        let formats: Array<Int> = (call.arguments as! Dictionary<String, Any?>)["formats"] as? Array ?? []
        let returnImage: Bool = (call.arguments as! Dictionary<String, Any?>)["returnImage"] as? Bool ?? false
        let speed: Int = (call.arguments as! Dictionary<String, Any?>)["speed"] as? Int ?? 0

        let formatList = formats.map { format in return BarcodeFormat(rawValue: format)}
        var barcodeOptions: BarcodeScannerOptions? = nil
        
         if (formatList.count != 0) {
             var barcodeFormats: BarcodeFormat = []
             for index in formats {
                 barcodeFormats.insert(BarcodeFormat(rawValue: index))
             }
             barcodeOptions = BarcodeScannerOptions(formats: barcodeFormats)
         }


        let position = facing == 0 ? AVCaptureDevice.Position.front : .back
        let detectionSpeed: DetectionSpeed = DetectionSpeed(rawValue: speed)!

        do {
            let parameters = try mobileScanner.start(barcodeScannerOptions: barcodeOptions, returnImage: returnImage, cameraPosition: position, torch: torch ? .on : .off, detectionSpeed: detectionSpeed)
            result(["textureId": parameters.textureId, "size": ["width": parameters.width, "height": parameters.height], "torchable": parameters.hasTorch])
        } catch MobileScannerError.alreadyStarted {
            result(FlutterError(code: "MobileScanner",
                                message: "Called start() while already started!",
                                details: nil))
        } catch MobileScannerError.noCamera {
            result(FlutterError(code: "MobileScanner",
                                message: "No camera found or failed to open camera!",
                                details: nil))
        } catch MobileScannerError.torchError(let error) {
            result(FlutterError(code: "MobileScanner",
                                message: "Error occured when setting torch!",
                                details: error))
        } catch MobileScannerError.cameraError(let error) {
            result(FlutterError(code: "MobileScanner",
                                message: "Error occured when setting up camera!",
                                details: error))
        } catch {
            result(FlutterError(code: "MobileScanner",
                                message: "Unknown error occured..",
                                details: nil))
        }
    }

    /// Stops the mobileScanner and closes the texture
    private func stop(_ result: @escaping FlutterResult) {
        do {
            try mobileScanner.stop()
        } catch {
            result(FlutterError(code: "MobileScanner",
                                message: "Called stop() while already stopped!",
                                details: nil))
        }
        result(nil)
    }

    /// Toggles the torch
    private func toggleTorch(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        do {
            try mobileScanner.toggleTorch(call.arguments as? Int == 1 ? .on : .off)
        } catch {
            result(FlutterError(code: "MobileScanner",
                                message: "Called toggleTorch() while stopped!",
                                details: nil))
        }
        result(nil)
    }
    
    /// Analyzes a single image
    private func analyzeImage(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let uiImage = UIImage(contentsOfFile: call.arguments as? String ?? "")
        
        if (uiImage == nil) {
            result(FlutterError(code: "MobileScanner",
                                message: "No image found in analyzeImage!",
                                details: nil))
            return
        }
        mobileScanner.analyzeImage(image: uiImage!, position: AVCaptureDevice.Position.back, callback: { [self] barcodes, error in
            if error == nil && barcodes != nil {
                for barcode in barcodes! {
                    let event: [String: Any?] = ["name": "barcode", "data": barcode.data]
                    barcodeHandler.publishEvent(event)
                }
            } else if error != nil {
                barcodeHandler.publishEvent(["name": "error", "message": error?.localizedDescription])
            }
        })
        result(nil)
    }
    
    /// Observer for torch state
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "torchMode":
            // off = 0; on = 1; auto = 2;
            let state = change?[.newKey] as? Int
            barcodeHandler.publishEvent(["name": "torchState", "data": state])
        default:
            break
        }
    }
}
