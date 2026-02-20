import 'dart:js_interop';
import 'dart:ui';

import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/barcode_type.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/objects/barcode_bytes.dart';
import 'package:web/web.dart' as web;

/// JS interop for the `window.ZXingWASM` global set by the zxing-wasm IIFE
/// build.
///
/// See https://github.com/Sec-ant/zxing-wasm
@JS('ZXingWASM')
external ZXingWasmModule get zxingWasmModule;

/// The `ZXingWASM` global object exposed by the IIFE reader build.
@JS()
extension type ZXingWasmModule(JSObject _) implements JSObject {
  /// Detect barcodes in [imageData].
  ///
  /// Returns a [JSPromise] that resolves to a list of [ZXingWasmReadResult]s.
  external JSPromise<JSArray<ZXingWasmReadResult>> readBarcodes(
    web.ImageData imageData,
    ZXingWasmReaderOptions options,
  );
}

/// Options passed to [ZXingWasmModule.readBarcodes].
@JS()
extension type ZXingWasmReaderOptions._(JSObject _) implements JSObject {
  /// Creates reader options.
  external factory ZXingWasmReaderOptions({
    /// Barcode format filter. Pass `null` or omit to detect all formats.
    JSArray<JSString>? formats,

    /// Spend more time to improve detection accuracy. Defaults to `true`.
    bool tryHarder,

    /// Also try 90°/180°/270° rotations. Defaults to `true`.
    bool tryRotate,

    /// Also try inverted/reversed reflectance. Defaults to `false`.
    bool tryInvert,
  });
}

/// A single barcode result returned by [ZXingWasmModule.readBarcodes].
@JS()
extension type ZXingWasmReadResult(JSObject _) implements JSObject {
  /// Decoded text content.
  external String? get text;

  /// Barcode format name, e.g. `'QRCode'`, `'EAN-13'`, `'Code128'`.
  external String get format;

  /// Raw barcode bytes as returned by the decoder.
  external JSUint8Array? get bytes;

  /// Corner positions in image pixel coordinates.
  external ZXingWasmPosition get position;

  /// Whether the result passed all integrity checks (checksum, etc.).
  external bool get isValid;
}

/// Corner positions of a detected barcode in image pixel coordinates.
@JS()
extension type ZXingWasmPosition(JSObject _) implements JSObject {
  /// Top-left corner, or `null` if not available.
  external ZXingWasmPoint? get topLeft;

  /// Top-right corner, or `null` if not available.
  external ZXingWasmPoint? get topRight;

  /// Bottom-right corner, or `null` if not available.
  external ZXingWasmPoint? get bottomRight;

  /// Bottom-left corner, or `null` if not available.
  external ZXingWasmPoint? get bottomLeft;
}

/// A 2-D point in image pixel coordinates, used for barcode corner positions.
@JS()
extension type ZXingWasmPoint(JSObject _) implements JSObject {
  /// Horizontal coordinate in image pixel space.
  external double get x;

  /// Vertical coordinate in image pixel space.
  external double get y;
}

/// Converts a [ZXingWasmReadResult] to a [Barcode].
extension ZXingWasmReadResultToBarcode on ZXingWasmReadResult {
  /// Converts this result to a [Barcode].
  Barcode get toBarcode {
    final pos = position;
    final corners = <Offset>[];

    final tl = pos.topLeft;
    final tr = pos.topRight;
    final br = pos.bottomRight;
    final bl = pos.bottomLeft;

    if (tl != null && tr != null && br != null && bl != null) {
      corners.addAll([
        Offset(tl.x, tl.y),
        Offset(tr.x, tr.y),
        Offset(br.x, br.y),
        Offset(bl.x, bl.y),
      ]);
    }

    final rawBytes = bytes?.toDart;

    return Barcode(
      corners: corners,
      format: format.toBarcodeFormat,
      displayValue: text,
      // Populate deprecated rawBytes for backward compatibility.
      // ignore: deprecated_member_use_from_same_package
      rawBytes: rawBytes,
      rawDecodedBytes:
          rawBytes != null ? DecodedBarcodeBytes(bytes: rawBytes) : null,
      rawValue: text,
      size: _computeSize(corners),
      type: BarcodeType.text,
    );
  }

  Size _computeSize(List<Offset> corners) {
    if (corners.length != 4) return Size.zero;
    final xs = corners.map((c) => c.dx);
    final ys = corners.map((c) => c.dy);
    return Size(
      xs.reduce((a, b) => a > b ? a : b) - xs.reduce((a, b) => a < b ? a : b),
      ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b),
    );
  }
}

/// Maps a zxing-wasm format string to [BarcodeFormat].
extension ZXingWasmFormatStringToBarcodeFormat on String {
  /// Converts a zxing-wasm format string (e.g. `'QRCode'`) to a
  /// [BarcodeFormat] enum value.
  BarcodeFormat get toBarcodeFormat => switch (this) {
    'Aztec' => BarcodeFormat.aztec,
    'Codabar' => BarcodeFormat.codabar,
    'Code39' => BarcodeFormat.code39,
    'Code93' => BarcodeFormat.code93,
    'Code128' => BarcodeFormat.code128,
    'DataMatrix' => BarcodeFormat.dataMatrix,
    'EAN-8' => BarcodeFormat.ean8,
    'EAN-13' => BarcodeFormat.ean13,
    'ITF' => BarcodeFormat.itf,
    'PDF417' => BarcodeFormat.pdf417,
    'QRCode' => BarcodeFormat.qrCode,
    'UPC-A' => BarcodeFormat.upcA,
    'UPC-E' => BarcodeFormat.upcE,
    _ => BarcodeFormat.unknown,
  };
}

/// Maps a [BarcodeFormat] to a zxing-wasm format string, or `null` if the
/// format is not supported by zxing-wasm.
extension BarcodeFormatToZXingWasmString on BarcodeFormat {
  /// Converts a [BarcodeFormat] to a zxing-wasm format string
  /// (e.g. `'QRCode'`), or `null` if the format is not supported.
  String? get toZXingWasmString => switch (this) {
    BarcodeFormat.aztec => 'Aztec',
    BarcodeFormat.codabar => 'Codabar',
    BarcodeFormat.code39 => 'Code39',
    BarcodeFormat.code93 => 'Code93',
    BarcodeFormat.code128 => 'Code128',
    BarcodeFormat.dataMatrix => 'DataMatrix',
    BarcodeFormat.ean8 => 'EAN-8',
    BarcodeFormat.ean13 => 'EAN-13',
    BarcodeFormat.itf ||
    BarcodeFormat.itf14 ||
    BarcodeFormat.itf2of5 ||
    BarcodeFormat.itf2of5WithChecksum =>
      'ITF',
    BarcodeFormat.pdf417 => 'PDF417',
    BarcodeFormat.qrCode => 'QRCode',
    BarcodeFormat.upcA => 'UPC-A',
    BarcodeFormat.upcE => 'UPC-E',
    BarcodeFormat.all || BarcodeFormat.unknown || _ => null,
  };
}
