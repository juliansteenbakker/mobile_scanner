//
//  DeviceOrientationStreamHandler.swift
//  Pods
//
//  Created by Julian Steenbakker on 21/04/2025.
//

#if os(iOS)
  import Flutter
  import UIKit

class DeviceOrientationStreamHandler: NSObject, FlutterStreamHandler {

    private var eventSink: FlutterEventSink?
    private var orientationObserver: NSObjectProtocol?
    private var lastSentOrientation: UIInterfaceOrientation?
    private var lastSentDeviceOrientation: UIDeviceOrientation?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.sendCurrentOrientation()
        }

        sendCurrentOrientation() // Send initial orientation
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let observer = orientationObserver {
            NotificationCenter.default.removeObserver(observer)
            orientationObserver = nil
        }

        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        eventSink = nil
        lastSentOrientation = nil
        lastSentDeviceOrientation = nil
        return nil
    }

    /// Send the current orientation to the Dart code, if it differs from the orientation that was last sent.
    @discardableResult
    func sendCurrentOrientation() -> Bool {
        guard let sink = eventSink else { return false }

        // Use interface orientation instead of device orientation
        // This respects Flutter's setPreferredOrientations
        if #available(iOS 13.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return false
            }

            let interfaceOrientation = windowScene.interfaceOrientation

            // Only send event if interface orientation has changed
            if lastSentOrientation == interfaceOrientation {
                return false
            }

            lastSentOrientation = interfaceOrientation

            let orientationString: String
            switch interfaceOrientation {
            case .portrait:
                orientationString = "PORTRAIT_UP"
            case .portraitUpsideDown:
                orientationString = "PORTRAIT_DOWN"
            case .landscapeLeft:
                orientationString = "LANDSCAPE_LEFT"
            case .landscapeRight:
                orientationString = "LANDSCAPE_RIGHT"
            default:
                return false
            }

            sink(orientationString)
            return true
        } else {
            // Fallback for iOS < 13: use device orientation
            let orientation = UIDevice.current.orientation

            if orientation == .faceUp || orientation == .faceDown {
                return false
            }
            
            // Only send event if device orientation has changed
            if lastSentDeviceOrientation == orientation {
                return false
            }

            lastSentDeviceOrientation = orientation

            let orientationString = orientation.toOrientationString
            sink(orientationString)
            return true
        }
    }
}

#endif
