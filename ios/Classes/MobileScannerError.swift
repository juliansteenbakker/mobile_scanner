//
//  MobileScannerError.swift
//  mobile_scanner
//
//  Created by Julian Steenbakker on 24/08/2022.
//
import Foundation

enum MobileScannerError: Error {
    case noCamera
    case alreadyStarted
    case alreadyStopped
    case torchError(_ error: Error)
    case cameraError(_ error: Error)
    case torchWhenStopped
    case zoomWhenStopped
    case zoomError(_ error: Error)
    case analyzerError(_ error: Error)
}
