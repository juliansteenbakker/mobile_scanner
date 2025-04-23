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

        let orientationString = orientation.toOrientationString
        sink(orientationString)
    }
}

#endif
