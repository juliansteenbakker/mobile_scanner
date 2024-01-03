import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui';

import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/barcode_type.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/web/zxing/result_point.dart';

/// The JS static interop class for the Result class in the ZXing library.
///
/// See also: https://github.com/zxing-js/library/blob/master/src/core/Result.ts
@JS()
@anonymous
@staticInterop
abstract class Result {}

extension ResultExt on Result {
  @JS('barcodeFormat')
  external JSNumber? get _barcodeFormat;

  @JS('text')
  external JSString? get _text;

  @JS('rawBytes')
  external JSUint8Array? get _rawBytes;

  @JS('resultPoints')
  external JSArray? get _resultPoints;

  @JS('timestamp')
  external JSNumber? get _timestamp;

  /// Get the barcode format of the result.
  ///
  /// See also https://github.com/zxing-js/library/blob/master/src/core/BarcodeFormat.ts
  BarcodeFormat get barcodeFormat {
    switch (_barcodeFormat?.toDartInt) {
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

  /// Get the corner points of the result.
  List<Offset> get resultPoints {
    final JSArray? points = _resultPoints;

    if (points == null) {
      return [];
    }

    return points.toDart.cast<ResultPoint>().map((point) {
      return Offset(point.x, point.y);
    }).toList();
  }

  /// Get the raw bytes of the result.
  Uint8List? get rawBytes => _rawBytes?.toDart;

  /// Get the text of the result.
  String? get text => _text?.toDart;

  /// Get the timestamp of the result.
  int? get timestamp => _timestamp?.toDartInt;

  /// Convert this result to a [Barcode].
  Barcode get toBarcode {
    return Barcode(
      corners: resultPoints,
      format: barcodeFormat,
      displayValue: text,
      rawBytes: rawBytes,
      rawValue: text,
      type: BarcodeType.text,
    );
  }
}
