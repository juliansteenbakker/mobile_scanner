import AVFoundation

#if os(iOS)
import UIKit
#endif

class VideoRotationController {
    var previewAngle: CGFloat? { nil }

    static func apply(to connection: AVCaptureConnection, controller: VideoRotationController?) {
#if os(iOS)
        if #available(iOS 17.0, *), let angle = controller?.previewAngle,
           connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
            return
        }
#endif
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = getVideoOrientation()
        }
    }

    static func getVideoOrientation() -> AVCaptureVideoOrientation {
#if os(iOS)
        if #available(iOS 13.0, *), let orientation = windowScene?.interfaceOrientation {
            switch orientation {
            case .portrait: return .portrait
            case .portraitUpsideDown: return .portraitUpsideDown
            case .landscapeLeft: return .landscapeLeft
            case .landscapeRight: return .landscapeRight
            default: return .portrait
            }
        }
#endif
        return .portrait
    }

#if os(iOS)
    static func make(device: AVCaptureDevice, onRotationChanged: @escaping () -> Void) -> VideoRotationController? {
        guard #available(iOS 17.0, *), let layer = flutterViewLayer else { return nil }
        return HorizonVideoRotationController(device: device, layer: layer, onRotationChanged: onRotationChanged)
    }

    @available(iOS 13.0, *)
    private static var windowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes.first as? UIWindowScene
    }

    @available(iOS 13.0, *)
    private static var flutterViewLayer: CALayer? {
        let windows = windowScene?.windows
        let window = windows?.first(where: { $0.isKeyWindow }) ?? windows?.first
        return window?.rootViewController?.view.layer
    }

    static func rotatedFrameSize(for dimensions: CMVideoDimensions, connection: AVCaptureConnection?) -> CGSize {
        let isQuarterTurn: Bool
        if #available(iOS 17.0, *), let angle = connection?.videoRotationAngle {
            isQuarterTurn = angle == 90 || angle == 270
        } else {
            let orientation = connection?.videoOrientation ?? .portrait
            isQuarterTurn = orientation == .portrait || orientation == .portraitUpsideDown
        }
        let width = CGFloat(dimensions.width)
        let height = CGFloat(dimensions.height)
        return isQuarterTurn ? CGSize(width: height, height: width) : CGSize(width: width, height: height)
    }

    /// Dart swaps this size itself when the interface is in landscape.
    static func portraitInterfaceSize(ofFrame size: CGSize) -> CGSize {
        let orientation = getVideoOrientation()
        let interfaceIsLandscape = orientation == .landscapeLeft || orientation == .landscapeRight
        return interfaceIsLandscape ? CGSize(width: size.height, height: size.width) : size
    }
#endif
}

#if os(iOS)
@available(iOS 17.0, *)
private final class HorizonVideoRotationController: VideoRotationController {
    private let coordinator: AVCaptureDevice.RotationCoordinator
    private var observation: NSKeyValueObservation?

    override var previewAngle: CGFloat? { coordinator.videoRotationAngleForHorizonLevelPreview }

    init(device: AVCaptureDevice, layer: CALayer, onRotationChanged: @escaping () -> Void) {
        coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: layer)
        super.init()
        observation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview) { _, _ in
            onRotationChanged()
        }
    }
}
#endif
