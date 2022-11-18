//
//  Util.swift
//  camerax
//
//  Created by 闫守旺 on 2021/2/6.
//

import AVFoundation
import Flutter
import Foundation
import MLKitBarcodeScanning

extension Error {
    func throwNative(_ result: FlutterResult) {
        let error = FlutterError(code: localizedDescription, message: nil, details: nil)
        result(error)
    }
}

extension CVBuffer {
    var image: UIImage {
        let ciImage = CIImage(cvPixelBuffer: self)
        let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent)
        return UIImage(cgImage: cgImage!, scale: 1.0, orientation: UIImage.Orientation.left)
    }
    
    var image1: UIImage {
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(self)
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        // Create a device-dependent RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // Create a bitmap graphics context with the sample buffer data
        var bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        //let bitmapInfo: UInt32 = CGBitmapInfo.alphaInfoMask.rawValue
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        // Create a Quartz image from the pixel data in the bitmap graphics context
        let quartzImage = context?.makeImage()
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        // Create an image object from the Quartz image
        return  UIImage(cgImage: quartzImage!)
    }
}

extension UIDeviceOrientation {
    func imageOrientation(position: AVCaptureDevice.Position) -> UIImage.Orientation {
        switch self {
        case .portrait:
            return position == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return position == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return position == .front ? .rightMirrored : .left
        case .landscapeRight:
            return position == .front ? .upMirrored : .down
        default:
            return .up
        }
    }
}

extension Barcode {
    var data: [String: Any?] {
        let corners = cornerPoints?.map({$0.cgPointValue.data})
        return ["corners": corners, "format": format.rawValue, "rawBytes": rawData, "rawValue": rawValue, "type": valueType.rawValue, "calendarEvent": calendarEvent?.data, "contactInfo": contactInfo?.data, "driverLicense": driverLicense?.data, "email": email?.data, "geoPoint": geoPoint?.data, "phone": phone?.data, "sms": sms?.data, "url": url?.data, "wifi": wifi?.data, "displayValue": displayValue]
    }
}

extension CGPoint {
    var data: [String: Any?] {
        let x1 = NSNumber(value: x.native)
        let y1 = NSNumber(value: y.native)
        return ["x": x1, "y": y1]
    }
}

extension BarcodeCalendarEvent {
    var data: [String: Any?] {
        return ["description": eventDescription, "end": end?.rawValue, "location": location, "organizer": organizer, "start": start?.rawValue, "status": status, "summary": summary]
    }
}

extension Date {
    var rawValue: String {
        return ISO8601DateFormatter().string(from: self)
    }
}

extension BarcodeContactInfo {
    var data: [String: Any?] {
        return ["addresses": addresses?.map({$0.data}), "emails": emails?.map({$0.data}), "name": name?.data, "organization": organization, "phones": phones?.map({$0.data}), "title": jobTitle, "urls": urls]
    }
}

extension BarcodeAddress {
    var data: [String: Any?] {
        return ["addressLines": addressLines, "type": type.rawValue]
    }
}

extension BarcodePersonName {
    var data: [String: Any?] {
        return ["first": first, "formattedName": formattedName, "last": last, "middle": middle, "prefix": prefix, "pronunciation": pronunciation, "suffix": suffix]
    }
}

extension BarcodeDriverLicense {
    var data: [String: Any?] {
        return ["addressCity": addressCity, "addressState": addressState, "addressStreet": addressStreet, "addressZip": addressZip, "birthDate": birthDate, "documentType": documentType, "expiryDate": expiryDate, "firstName": firstName, "gender": gender, "issueDate": issuingDate, "issuingCountry": issuingCountry, "lastName": lastName, "licenseNumber": licenseNumber, "middleName": middleName]
    }
}

extension BarcodeEmail {
    var data: [String: Any?] {
        return ["address": address, "body": body, "subject": subject, "type": type.rawValue]
    }
}

extension BarcodeGeoPoint {
    var data: [String: Any?] {
        return ["latitude": latitude, "longitude": longitude]
    }
}

extension BarcodePhone {
    var data: [String: Any?] {
        return ["number": number, "type": type.rawValue]
    }
}

extension BarcodeSMS {
    var data: [String: Any?] {
        return ["message": message, "phoneNumber": phoneNumber]
    }
}

extension BarcodeURLBookmark {
    var data: [String: Any?] {
        return ["title": title, "url": url]
    }
}

extension BarcodeWifi {
    var data: [String: Any?] {
        return ["encryptionType": type.rawValue, "password": password, "ssid": ssid]
    }
}
