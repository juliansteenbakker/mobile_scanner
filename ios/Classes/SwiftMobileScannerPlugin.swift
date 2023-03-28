import Flutter
import MLKitVision
import MLKitBarcodeScanning
import AVFoundation
import UIKit

public class SwiftMobileScannerPlugin: NSObject, FlutterPlugin {
    
    /// The mobile scanner object that handles all logic
    private let mobileScanner: MobileScanner
    
    /// The handler sends all information via an event channel back to Flutter
    private let barcodeHandler: BarcodeHandler

    static var scanWindow: [CGFloat]?
    
    private static func isBarcodeInScanWindow(barcode: Barcode, imageSize: CGSize) -> Bool {
        let scanwindow = SwiftMobileScannerPlugin.scanWindow!
        let barcodeminX = barcode.cornerPoints![0].cgPointValue.x
        let barcodeminY = barcode.cornerPoints![1].cgPointValue.y
        
        let barcodewidth = barcode.cornerPoints![2].cgPointValue.x - barcodeminX
        let barcodeheight = barcode.cornerPoints![3].cgPointValue.y - barcodeminY
        let barcodeBox = CGRect(x: barcodeminX, y: barcodeminY, width: barcodewidth, height: barcodeheight)

        
        let minX = scanwindow[0] * imageSize.width
        let minY = scanwindow[1] * imageSize.height

        let width = (scanwindow[2] * imageSize.width)  - minX
        let height = (scanwindow[3] * imageSize.height) - minY

        let scaledWindow =  CGRect(x: minX, y: minY, width: width, height: height)
        
        return scaledWindow.contains(barcodeBox)
    }
    
    init(barcodeHandler: BarcodeHandler, registry: FlutterTextureRegistry) {
        self.mobileScanner = MobileScanner(registry: registry, mobileScannerCallback: { barcodes, error, image in
            if barcodes != nil {
                let barcodesMap: [Any?] = barcodes!.compactMap { barcode in
                    if (SwiftMobileScannerPlugin.scanWindow != nil) {
                        if (SwiftMobileScannerPlugin.isBarcodeInScanWindow(barcode: barcode, imageSize: image.size)) {
                            return barcode.data
                        } else {
                            return nil
                        }
                    } else {
                        return barcode.data
                    }
                }
                if (!barcodesMap.isEmpty) {
                    barcodeHandler.publishEvent(["name": "barcode", "data": barcodesMap, "image": FlutterStandardTypedData(bytes: image.jpegData(compressionQuality: 0.8)!), "width": image.size.width, "height": image.size.height])
                }
            } else if (error != nil){
                barcodeHandler.publishEvent(["name": "error", "data": error!.localizedDescription])
            }
        }, torchModeChangeCallback: { torchState in
            barcodeHandler.publishEvent(["name": "torchState", "data": torchState])
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
        case "setScale":
            setScale(call, result)
        case "updateScanWindow":
            updateScanWindow(call, result)
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
        } catch {}
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
    
    /// Toggles the zoomScale
    private func setScale(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        var scale = call.arguments as? CGFloat
        if (scale == nil) {
            result(FlutterError(code: "MobileScanner",
                                              message: "You must provide a scale when calling setScale!",
                                              details: nil))
            return
        }
        do {
            try mobileScanner.setScale(scale!)
        } catch MobileScannerError.zoomWhenStopped {
            result(FlutterError(code: "MobileScanner",
                                message: "Called setScale() while stopped!",
                                details: nil))
        } catch MobileScannerError.zoomError(let error) {
            result(FlutterError(code: "MobileScanner",
                                message: "Error while zooming.",
                                details: error))
        } catch {
            result(FlutterError(code: "MobileScanner",
                                message: "Error while zooming.",
                                details: nil))
        }
        result(nil)
    }
    
    /// Toggles the torch
    func updateScanWindow(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let scanWindowData: Array? = (call.arguments as? [String: Any])?["rect"] as? [CGFloat]
        SwiftMobileScannerPlugin.scanWindow = scanWindowData

        result(nil)
    }
    
    static func arrayToRect(scanWindowData: [CGFloat]?) -> CGRect? {
        if (scanWindowData == nil) {
            return nil
        }

        let minX = scanWindowData![0]
        let minY = scanWindowData![1]

        let width = scanWindowData![2]  - minX
        let height = scanWindowData![3] - minY

        return CGRect(x: minX, y: minY, width: width, height: height)
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
            if error == nil && barcodes != nil && !barcodes!.isEmpty {
                let barcodesMap: [Any?] = barcodes!.compactMap { barcode in barcode.data }
                let event: [String: Any?] = ["name": "barcode", "data": barcodesMap]
                barcodeHandler.publishEvent(event)
                result(true)
            } else {
                if error != nil {
                    barcodeHandler.publishEvent(["name": "error", "message": error?.localizedDescription])
                }
                result(false)
            }
        })
    }
}
