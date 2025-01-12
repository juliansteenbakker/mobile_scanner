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
extension type Result(JSObject _) implements JSObject {
  @JS('barcodeFormat')
  external int? get _barcodeFormat;

  /// Get the text of the result.
  external String? get text;

  @JS('rawBytes')
  external JSUint8Array? get _rawBytes;

  @JS('resultPoints')
  external JSArray<ResultPoint>? get _resultPoints;

  /// Get the timestamp of the result.
  external int? get timestamp;

  /// Get the barcode format of the result.
  ///
  /// See also https://github.com/zxing-js/library/blob/master/src/core/BarcodeFormat.ts
  BarcodeFormat get barcodeFormat {
    return switch (_barcodeFormat) {
      0 => BarcodeFormat.aztec,
      1 => BarcodeFormat.codabar,
      2 => BarcodeFormat.code39,
      3 => BarcodeFormat.code93,
      4 => BarcodeFormat.code128,
      5 => BarcodeFormat.dataMatrix,
      6 => BarcodeFormat.ean8,
      7 => BarcodeFormat.ean13,
      8 => BarcodeFormat.itf,
      // Maxicode
      9 => BarcodeFormat.unknown,
      10 => BarcodeFormat.pdf417,
      11 => BarcodeFormat.qrCode,
      // RSS 14
      12 => BarcodeFormat.unknown,
      // RSS EXPANDED
      13 => BarcodeFormat.unknown,
      14 => BarcodeFormat.upcA,
      15 => BarcodeFormat.upcE,
      // UPC/EAN extension
      16 => BarcodeFormat.unknown,
      _ => BarcodeFormat.unknown
    };
  }

  /// Get the raw bytes of the result.
  Uint8List? get rawBytes => _rawBytes?.toDart;

  /// Get the corner points of the result.
  List<Offset> get resultPoints {
    final JSArray<ResultPoint>? points = _resultPoints;

    if (points == null) {
      return const [];
    }

    return points.toDart.map((point) {
      return Offset(point.x, point.y);
    }).toList();
  }

  /// Convert this result to a [Barcode].
  Barcode get toBarcode {
    final List<Offset> corners = resultPoints;

    return Barcode(
      corners: corners,
      format: barcodeFormat,
      displayValue: text,
      rawBytes: rawBytes,
      rawValue: text,
      size: _computeSize(corners),
      type: BarcodeType.text,
    );
  }

  Size _computeSize(List<Offset> points) {
    if (points.length != 4) {
      return Size.zero;
    }

    final Iterable<double> xCoords = points.map((p) => p.dx);
    final Iterable<double> yCoords = points.map((p) => p.dy);

    // Find the minimum and maximum x and y coordinates.
    final double xMin = xCoords.reduce((a, b) => a < b ? a : b);
    final double xMax = xCoords.reduce((a, b) => a > b ? a : b);
    final double yMin = yCoords.reduce((a, b) => a < b ? a : b);
    final double yMax = yCoords.reduce((a, b) => a > b ? a : b);

    return Size(xMax - xMin, yMax - yMin);
  }
}
