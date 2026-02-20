import 'dart:js_interop';

import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:web/web.dart' as web;

/// Checks whether the native BarcodeDetector API is available in this browser.
///
/// Returns `true` when `BarcodeDetector` is defined on `globalThis` **and**
/// `BarcodeDetector.getSupportedFormats()` resolves to a non-empty list.
Future<bool> isBarcodeDetectorSupported() async {
  try {
    final formats = await NativeBarcodeDetector.getSupportedFormats().toDart;
    return formats.toDart.isNotEmpty;
  } on Object {
    return false;
  }
}

/// The JS `BarcodeDetector` class from the Shape Detection API.
///
/// See https://developer.mozilla.org/en-US/docs/Web/API/BarcodeDetector
@JS('BarcodeDetector')
extension type NativeBarcodeDetector._(JSObject _) implements JSObject {
  /// Constructs a detector that recognises all supported formats.
  external factory NativeBarcodeDetector();

  /// Constructs a detector restricted to the given [options].
  @JS('BarcodeDetector')
  external factory NativeBarcodeDetector.withOptions(
    BarcodeDetectorInit options,
  );

  /// Returns the list of barcode formats supported by the current browser.
  external static JSPromise<JSArray<JSString>> getSupportedFormats();

  /// Detects barcodes in [videoElement].
  ///
  /// Returns a [JSPromise] that resolves to a list of [DetectedBarcode]s.
  /// Corner points are in the intrinsic coordinate space of the video
  /// frame (i.e. `[0, videoWidth] × [0, videoHeight]`).
  external JSPromise<JSArray<DetectedBarcode>> detect(
    web.HTMLVideoElement videoElement,
  );
}

/// Options object for [NativeBarcodeDetector.withOptions].
@JS()
extension type BarcodeDetectorInit._(JSObject _) implements JSObject {
  /// Creates an init object restricting detection to the given [formats].
  external factory BarcodeDetectorInit({required JSArray<JSString> formats});
}

/// A single barcode result from [NativeBarcodeDetector.detect].
@JS()
extension type DetectedBarcode(JSObject _) implements JSObject {
  /// Decoded text content of the barcode.
  external String get rawValue;

  /// Barcode format string, e.g. `'qr_code'`, `'ean_13'`.
  external String get format;

  /// The four corner points of the barcode in video pixel coordinates.
  external JSArray<BarcodePoint> get cornerPoints;
}

/// A 2-D point returned as a corner position by [DetectedBarcode].
@JS()
extension type BarcodePoint(JSObject _) implements JSObject {
  /// Horizontal coordinate in video pixel space.
  external double get x;

  /// Vertical coordinate in video pixel space.
  external double get y;
}

/// Maps a BarcodeDetector format string to [BarcodeFormat].
extension BarcodeDetectorFormatStringToBarcodeFormat on String {
  /// Converts a BarcodeDetector format string (e.g. `'qr_code'`) to a
  /// [BarcodeFormat] enum value.
  BarcodeFormat get toBarcodeFormat => switch (this) {
    'aztec' => BarcodeFormat.aztec,
    'codabar' => BarcodeFormat.codabar,
    'code_39' => BarcodeFormat.code39,
    'code_93' => BarcodeFormat.code93,
    'code_128' => BarcodeFormat.code128,
    'data_matrix' => BarcodeFormat.dataMatrix,
    'ean_8' => BarcodeFormat.ean8,
    'ean_13' => BarcodeFormat.ean13,
    'itf' => BarcodeFormat.itf,
    'pdf417' => BarcodeFormat.pdf417,
    'qr_code' => BarcodeFormat.qrCode,
    'upc_a' => BarcodeFormat.upcA,
    'upc_e' => BarcodeFormat.upcE,
    _ => BarcodeFormat.unknown,
  };
}

/// Maps a [BarcodeFormat] to a BarcodeDetector format string, or `null` if
/// the format is not supported by the BarcodeDetector API.
extension BarcodeFormatToBarcodeDetectorString on BarcodeFormat {
  /// Converts a [BarcodeFormat] to a BarcodeDetector format string
  /// (e.g. `'qr_code'`), or `null` if the format is not supported.
  String? get toBarcodeDetectorString => switch (this) {
    BarcodeFormat.aztec => 'aztec',
    BarcodeFormat.codabar => 'codabar',
    BarcodeFormat.code39 => 'code_39',
    BarcodeFormat.code93 => 'code_93',
    BarcodeFormat.code128 => 'code_128',
    BarcodeFormat.dataMatrix => 'data_matrix',
    BarcodeFormat.ean8 => 'ean_8',
    BarcodeFormat.ean13 => 'ean_13',
    BarcodeFormat.itf ||
    BarcodeFormat.itf14 ||
    BarcodeFormat.itf2of5 ||
    BarcodeFormat.itf2of5WithChecksum =>
      'itf',
    BarcodeFormat.pdf417 => 'pdf417',
    BarcodeFormat.qrCode => 'qr_code',
    BarcodeFormat.upcA => 'upc_a',
    BarcodeFormat.upcE => 'upc_e',
    BarcodeFormat.all || BarcodeFormat.unknown || _ => null,
  };
}
