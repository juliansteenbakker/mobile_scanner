import AVFoundation

/// Camera lens types matching AVCaptureDevice.DeviceType naming.
enum LensType: Int {
    case wideAngle = 0   // .builtInWideAngleCamera - standard 1x camera
    case ultraWide = 1   // .builtInUltraWideCamera - 0.5x camera
    case telephoto = 2   // .builtInTelephotoCamera - 2x+ camera
}

/// Utility class for camera selection and lens type detection.
class MobileScannerCameraSelector {

    /// Maps an AVCaptureDevice.DeviceType to a LensType.
    ///
    /// - Parameter deviceType: The device type to map
    /// - Returns: The corresponding LensType, or nil if not a recognized lens type
    @available(iOS 13.0, macOS 10.15, *)
    static func lensType(from deviceType: AVCaptureDevice.DeviceType) -> LensType? {
        switch deviceType {
        case .builtInWideAngleCamera:
            return .wideAngle
#if os(iOS)
        case .builtInUltraWideCamera:
            return .ultraWide
        case .builtInTelephotoCamera:
            return .telephoto
#endif
        default:
            return nil
        }
    }

    /// Select the appropriate camera based on position and lens type.
    ///
    /// - Parameters:
    ///   - position: The camera position (front or back)
    ///   - lensType: The desired lens type (LensType.wideAngle, LensType.ultraWide, LensType.telephoto, or any other value for default)
    /// - Returns: The selected AVCaptureDevice, or nil if not found
    static func selectCamera(position: AVCaptureDevice.Position, lensType: Int) -> AVCaptureDevice? {
        let requestedLens = LensType(rawValue: lensType)
        let isSpecificLensRequest = requestedLens != nil

#if os(iOS)
        if #available(iOS 13.0, *) {
            let deviceTypes: [AVCaptureDevice.DeviceType]

            switch requestedLens {
            case .wideAngle:
                deviceTypes = [.builtInWideAngleCamera]
            case .ultraWide:
                deviceTypes = [.builtInUltraWideCamera]
            case .telephoto:
                deviceTypes = [.builtInTelephotoCamera]
            case nil:
                // Any lens type - use default discovery order
                deviceTypes = [.builtInTripleCamera, .builtInDualCamera, .builtInWideAngleCamera]
            }

            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: deviceTypes,
                mediaType: .video,
                position: position
            )

            if let device = discoverySession.devices.first {
                return device
            }

            // Only use fallbacks for non-specific lens requests
            if !isSpecificLensRequest {
                let fallbackSession = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInWideAngleCamera],
                    mediaType: .video,
                    position: position
                )
                if let device = fallbackSession.devices.first {
                    return device
                }
            }
        }
#else
        if #available(macOS 10.15, *) {
            // macOS only has wide angle cameras
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: position
            )
            if let device = discoverySession.devices.first {
                return device
            }
        }
#endif

        // Only use legacy fallbacks for non-specific lens requests
        if isSpecificLensRequest {
            return nil
        }

        // Legacy fallback for older OS versions: filter by position
        if let device = AVCaptureDevice.devices(for: .video).filter({ $0.position == position }).first {
            return device
        }

        // Ultimate fallback: any available video device
        return AVCaptureDevice.default(for: .video)
    }

    /// Determine the best lens type for QR code scanning based on minimum focus distance.
    ///
    /// Selects the camera that can focus closest to the phone. On iOS 15+,
    /// `minimumFocusDistance` (millimeters, lower = shorter focus distance) is used.
    /// Fixed-focus cameras (minimumFocusDistance == -1) are skipped.
    ///
    /// **Naming note:** `LensType.wideAngle` (raw value 0) maps to the standard 1× camera
    /// (`builtInWideAngleCamera` in AVFoundation), which corresponds to `CameraLensType.normal`
    /// in the Dart API. `LensType.ultraWide` (raw value 1) is the 0.5× camera, which maps to
    /// `CameraLensType.wide` in Dart. These names reflect AVFoundation's conventions, not the
    /// Dart layer's conventions — the raw values are what matter for the method channel.
    ///
    /// Falls back to `LensType.wideAngle` (raw value 0 = Dart `normal`) on iOS < 15 or macOS,
    /// which is the standard main camera and a safe default for QR scanning.
    ///
    /// - Parameter position: The camera position to check (default: .back)
    /// - Returns: The LensType raw value best suited for close-up QR scanning
    static func getBestQrScanningLens(position: AVCaptureDevice.Position = .back) -> Int {
#if os(iOS)
        if #available(iOS 15.0, *) {
            let devices = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera],
                mediaType: .video,
                position: position
            ).devices

            // LensType.wideAngle = raw 0 = Dart normal (safe default)
            var bestLensType = LensType.wideAngle.rawValue
            var bestMfd = Int.max
            var foundAny = false

            for device in devices {
                guard let lens = lensType(from: device.deviceType) else { continue }
                let mfd = device.minimumFocusDistance
                if mfd < 0 { continue }  // -1 = fixed focus at infinity, skip
                if !foundAny || mfd < bestMfd {
                    bestMfd = mfd
                    bestLensType = lens.rawValue
                    foundAny = true
                }
            }
            return bestLensType
        }
#endif
        // Fallback: raw value 0 = LensType.wideAngle = Dart CameraLensType.normal (the 1× camera)
        return LensType.wideAngle.rawValue
    }

    /// Get the list of supported lens types on this device.
    ///
    /// - Returns: A sorted array of supported LensType raw values
    static func getSupportedLenses() -> [Int] {
#if os(iOS)
        if #available(iOS 13.0, *) {
            var supportedLenses = Set<Int>()

            // Check both back and front cameras
            for position: AVCaptureDevice.Position in [.back, .front] {
                let devices = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera],
                    mediaType: .video,
                    position: position
                ).devices

                for device in devices {
                    if let lensType = lensType(from: device.deviceType) {
                        supportedLenses.insert(lensType.rawValue)
                    }
                }
            }

            return supportedLenses.sorted()
        } else {
            // iOS < 13.0: assume at least wide-angle camera is available
            return [LensType.wideAngle.rawValue]
        }
#else
        // macOS: assume at least wide-angle camera is available
        return [LensType.wideAngle.rawValue]
#endif
    }
}
