//
//  DeviceOrientationStreamHandler.swift
//  Pods
//
//  Created by Julian Steenbakker on 21/04/2025.
//


import Flutter
import UIKit

class DeviceOrientationStreamHandler: NSObject, FlutterStreamHandler {
    
    private var eventSink: FlutterEventSink?
    private var orientationObserver: NSObjectProtocol?
    private let onOrientationChanged: ((UIDeviceOrientation) -> Void)?
    
    init(onOrientationChanged: ((UIDeviceOrientation) -> Void)? = nil) {
        self.onOrientationChanged = onOrientationChanged
        super.init()
    }

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
        return nil
    }

    private func sendCurrentOrientation() {
        guard let sink = eventSink else { return }

        let orientation = UIDevice.current.orientation
        
        if orientation == .faceUp || orientation == .faceDown {
            // Do not change when oriented flat.
            return
        }

        if (onOrientationChanged != nil) {
            onOrientationChanged!(orientation)
        }
        
        var orientationString: String
        
        switch orientation {
        case .portrait:
            orientationString = "PORTRAIT_UP"
        case .portraitUpsideDown:
            orientationString = "PORTRAIT_DOWN"
        case .landscapeLeft:
            orientationString = "LANDSCAPE_LEFT"
        case .landscapeRight:
            orientationString = "LANDSCAPE_RIGHT"
        case .faceUp:
            orientationString = "PORTRAIT_UP"
        case .faceDown:
            orientationString = "PORTRAIT_DOWN"
        default:
            orientationString = "PORTRAIT_UP"
        }

        sink(orientationString)
    }
}
