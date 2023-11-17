import 'dart:js_interop';

import 'package:mobile_scanner/src/enums/barcode_format.dart';

/// The JS static interop class for the Result class in the ZXing library.
///
/// See also: https://github.com/zxing-js/library/blob/master/src/core/Result.ts
@JS()
@staticInterop
abstract class Result {}

extension ResultExt on Result {
  /// Get the barcode format.
  ///
  /// See also https://github.com/zxing-js/library/blob/master/src/core/BarcodeFormat.ts
  external JSFunction getBarcodeFormat;

  /// Get the raw bytes of the result.
  external JSFunction getRawBytes;

  /// Get the points of the result.
  external JSFunction getResultPoints;

  /// Get the text of the result.
  external JSFunction getText;

  /// Get the timestamp of the result.
  external JSFunction getTimestamp;

  /// Get the barcode format of the result.
  BarcodeFormat get barcodeFormat {
    final JSNumber? format = getBarcodeFormat.callAsFunction() as JSNumber?;

    switch (format?.toDartInt) {
      case 0:
        return BarcodeFormat.aztec;
      case 1:
        return BarcodeFormat.codabar;
      case 2:
        return BarcodeFormat.code39;
      case 3:
        return BarcodeFormat.code93;
      case 4:
        return BarcodeFormat.code128;
      case 5:
        return BarcodeFormat.dataMatrix;
      case 6:
        return BarcodeFormat.ean8;
      case 7:
        return BarcodeFormat.ean13;
      case 8:
        return BarcodeFormat.itf;
      case 9:
        // Maxicode
        return BarcodeFormat.unknown;
      case 10:
        return BarcodeFormat.pdf417;
      case 11:
        return BarcodeFormat.qrCode;
      case 12:
        // RSS 14
        return BarcodeFormat.unknown;
      case 13:
        // RSS EXPANDED
        return BarcodeFormat.unknown;
      case 14:
        return BarcodeFormat.upcA;
      case 15:
        return BarcodeFormat.upcE;
      case 16:
        // UPC/EAN extension
        return BarcodeFormat.unknown;
      default:
        return BarcodeFormat.unknown;
    }
  }
}
