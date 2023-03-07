//
//  SwiftMobileScanner.swift
//  mobile_scanner
//
//  Created by Julian Steenbakker on 15/02/2022.
//

import Foundation

import AVFoundation
import MLKitVision
import MLKitBarcodeScanning

typealias MobileScannerCallback = ((Array<Barcode>?, Error?, UIImage) -> ())
typealias TorchModeChangeCallback = ((Int?) -> ())

public class MobileScanner: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, FlutterTexture {
    /// Capture session of the camera
    var captureSession: AVCaptureSession!

    /// The selected camera
    var device: AVCaptureDevice!

    /// Barcode scanner for results
    var scanner = BarcodeScanner.barcodeScanner()

    /// Return image buffer with the Barcode event
    var returnImage: Bool = false

    /// Default position of camera
    var videoPosition: AVCaptureDevice.Position = AVCaptureDevice.Position.back

    /// When results are found, this callback will be called
    let mobileScannerCallback: MobileScannerCallback

    /// When torch mode is changes, this callback will be called
    let torchModeChangeCallback: TorchModeChangeCallback

    /// If provided, the Flutter registry will be used to send the output of the CaptureOutput to a Flutter texture.
    private let registry: FlutterTextureRegistry?

    /// Image to be sent to the texture
    var latestBuffer: CVImageBuffer!

    /// Texture id of the camera preview for Flutter
    private var textureId: Int64!

    var detectionSpeed: DetectionSpeed = DetectionSpeed.noDuplicates

    init(registry: FlutterTextureRegistry?, mobileScannerCallback: @escaping MobileScannerCallback, torchModeChangeCallback: @escaping TorchModeChangeCallback) {
        self.registry = registry
        self.mobileScannerCallback = mobileScannerCallback
        self.torchModeChangeCallback = torchModeChangeCallback
        super.init()
    }

    /// Check if we already have camera permission.
    func checkPermission() -> Int {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            return 0
        case .authorized:
            return 1
        default:
            return 2
        }
    }

    /// Request permissions for video
    func requestPermission(_ result: @escaping FlutterResult) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { result($0) })
    }
    
    /// Gets called when a new image is added to the buffer
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer from sample buffer.")
            return
        }
        latestBuffer = imageBuffer
        registry?.textureFrameAvailable(textureId)
        if ((detectionSpeed == DetectionSpeed.normal || detectionSpeed == DetectionSpeed.noDuplicates) && i > 10 || detectionSpeed == DetectionSpeed.unrestricted) {
            i = 0
            let ciImage = latestBuffer.image

            let image = VisionImage(image: ciImage)
            image.orientation = imageOrientation(
                deviceOrientation: UIDevice.current.orientation,
                defaultOrientation: .portrait,
                position: videoPosition
            )

            scanner.process(image) { [self] barcodes, error in
                if (detectionSpeed == DetectionSpeed.noDuplicates) {
                    let newScannedBarcodes = barcodes?.map { barcode in
                        return barcode.rawValue
                    }
                    if (error == nil && barcodesString != nil && newScannedBarcodes != nil && barcodesString!.elementsEqual(newScannedBarcodes!)) {
                        return
                    } else {
                        barcodesString = newScannedBarcodes
                    }
                }

                mobileScannerCallback(barcodes, error, ciImage)
            }
        } else {
            i+=1
        }
    }

    /// Start scanning for barcodes
    func start(barcodeScannerOptions: BarcodeScannerOptions?, returnImage: Bool, cameraPosition: AVCaptureDevice.Position, torch: AVCaptureDevice.TorchMode, detectionSpeed: DetectionSpeed) throws -> MobileScannerStartParameters {
        self.detectionSpeed = detectionSpeed
        if (device != nil) {
            throw MobileScannerError.alreadyStarted
        }

        scanner = barcodeScannerOptions != nil ? BarcodeScanner.barcodeScanner(options: barcodeScannerOptions!) : BarcodeScanner.barcodeScanner()
        captureSession = AVCaptureSession()
        textureId = registry?.register(self)

        // Open the camera device
        if #available(iOS 13.0, *) {
            device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: cameraPosition).devices.first
        } else {
            device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: cameraPosition).devices.first
        }

        if (device == nil) {
            throw MobileScannerError.noCamera
        }

        device.addObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode), options: .new, context: nil)
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if #available(iOS 15.4, *) {
                device.automaticallyAdjustsFaceDrivenAutoFocusEnabled = false
            }
            device.unlockForConfiguration()
        } catch {}

        captureSession.beginConfiguration()

        // Add device input
        do {
            let input = try AVCaptureDeviceInput(device: device)
            captureSession.addInput(input)
        } catch {
            throw MobileScannerError.cameraError(error)
        }

        captureSession.sessionPreset = AVCaptureSession.Preset.photo;
        // Add video output.
        let videoOutput = AVCaptureVideoDataOutput()

        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true

        videoPosition = cameraPosition
        // calls captureOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)

        captureSession.addOutput(videoOutput)
        for connection in videoOutput.connections {
            connection.videoOrientation = .portrait
            if cameraPosition == .front && connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        captureSession.commitConfiguration()
        captureSession.startRunning()
        // Enable the torch if parameter is set and torch is available
        // torch should be set after 'startRunning' is called
        do {
            try toggleTorch(torch)
        } catch {
            print("Failed to set initial torch state.")
        }
        let dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)

        return MobileScannerStartParameters(width: Double(dimensions.height), height: Double(dimensions.width), hasTorch: device.hasTorch, textureId: textureId)
    }

    /// Stop scanning for barcodes
    func stop() throws {
        if (device == nil) {
            throw MobileScannerError.alreadyStopped
        }
        captureSession.stopRunning()
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        device.removeObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode))
        registry?.unregisterTexture(textureId)
        textureId = nil
        captureSession = nil
        device = nil
    }

    /// Toggle the flashlight between on and off
    func toggleTorch(_ torch: AVCaptureDevice.TorchMode) throws {
        if (device == nil) {
            throw MobileScannerError.torchWhenStopped
        }
        if (device.hasTorch && device.isTorchAvailable) {
            do {
                try device.lockForConfiguration()
                device.torchMode = torch
                device.unlockForConfiguration()
            } catch {
                throw MobileScannerError.torchError(error)
            }
        }
    }

    // Observer for torch state
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "torchMode":
            // off = 0; on = 1; auto = 2;
            let state = change?[.newKey] as? Int
            torchModeChangeCallback(state)
        default:
            break
        }
    }
    
    /// Set the zoom factor of the camera
    func setScale(_ scale: CGFloat) throws {
        if (device == nil) {
            throw MobileScannerError.torchWhenStopped
        }
        
        do {
            try device.lockForConfiguration()
            var maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            
            var actualScale = (scale * 4) + 1
            
            // Set maximum zoomrate of 5x
            actualScale = min(5.0, actualScale)
            
            // Limit to max rate of camera
            actualScale = min(maxZoomFactor, actualScale)
            
            // Limit to 1.0 scale
            device.ramp(toVideoZoomFactor: actualScale, withRate: 5)
            device.unlockForConfiguration()
        } catch {
            throw MobileScannerError.zoomError(error)
        }
        
    }

    /// Analyze a single image
    func analyzeImage(image: UIImage, position: AVCaptureDevice.Position, callback: @escaping BarcodeScanningCallback) {
        let image = VisionImage(image: image)
        image.orientation = imageOrientation(
            deviceOrientation: UIDevice.current.orientation,
            defaultOrientation: .portrait,
            position: position
        )

        scanner.process(image, completion: callback)
    }

    var i = 0

    var barcodesString: Array<String?>?



//    /// Convert image buffer to jpeg
//    private func ciImageToJpeg(ciImage: CIImage) -> Data {
//
//        // let ciImage = CIImage(cvPixelBuffer: latestBuffer)
//        let context:CIContext = CIContext.init(options: nil)
//        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
//        let uiImage:UIImage = UIImage(cgImage: cgImage, scale: 1, orientation: UIImage.Orientation.up)
//
//        return uiImage.jpegData(compressionQuality: 0.8)!;
//    }

    /// Rotates images accordingly
    func imageOrientation(
        deviceOrientation: UIDeviceOrientation,
        defaultOrientation: UIDeviceOrientation,
        position: AVCaptureDevice.Position
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
            return imageOrientation(deviceOrientation: defaultOrientation, defaultOrientation: .portrait, position: .back)
        }
    }

    /// Sends output of OutputBuffer to a Flutter texture
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if latestBuffer == nil {
            return nil
        }
        return Unmanaged<CVPixelBuffer>.passRetained(latestBuffer)
    }
    
    struct MobileScannerStartParameters {
        var width: Double = 0.0
        var height: Double = 0.0
        var hasTorch = false
        var textureId: Int64 = 0
    }
}

