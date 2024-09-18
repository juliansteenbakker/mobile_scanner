//
//  MobileScannerErrorCodes.swift
//  mobile_scanner
//
//  Created by Navaron Bracke on 27/05/2024.
//

import Foundation

struct MobileScannerErrorCodes {
    static let ALREADY_STARTED_ERROR = "MOBILE_SCANNER_ALREADY_STARTED_ERROR"
    static let ALREADY_STARTED_ERROR_MESSAGE = "The scanner was already started."
    // The error code 'BARCODE_ERROR' does not have an error message,
    // because it uses the error message from the undelying error.
    static let BARCODE_ERROR = "MOBILE_SCANNER_BARCODE_ERROR"
    // The error code 'CAMERA_ERROR' does not have an error message,
    // because it uses the error message from the underlying error.       
    static let CAMERA_ERROR = "MOBILE_SCANNER_CAMERA_ERROR"
    static let NO_CAMERA_ERROR = "MOBILE_SCANNER_NO_CAMERA_ERROR"
    static let NO_CAMERA_ERROR_MESSAGE = "No cameras available."
}
