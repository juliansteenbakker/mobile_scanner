import 'dart:js_interop';

import 'package:js/js.dart';
import 'package:web/web.dart';

/// The JS interop class for the ZXing BrowserMultiFormatReader.
///
/// See https://github.com/zxing-js/library/blob/master/src/browser/BrowserMultiFormatReader.ts
@JS('ZXing.BrowserMultiFormatReader')
@staticInterop
class ZXingBrowserMultiFormatReader {
  /// Construct a new ZXingBrowserMultiFormatReader.
  ///
  /// The [hints] are the configuration options for the reader.
  /// The [timeBetweenScansMillis] is the allowed time between scans in milliseconds.
  ///
  /// See also: https://github.com/zxing-js/library/blob/master/src/core/DecodeHintType.ts
  external factory ZXingBrowserMultiFormatReader(
    JSAny? hints,
    int? timeBetweenScansMillis,
  );
}

extension ZXingBrowserMultiFormatReaderExt on ZXingBrowserMultiFormatReader {
  /// Set the source for the [HTMLVideoElement] that acts as input for the barcode reader.
  ///
  /// This function takes a [HTMLVideoElement], and a [MediaStream] as arguments,
  /// and returns no result.
  ///
  /// See https://github.com/zxing-js/library/blob/master/src/browser/BrowserCodeReader.ts#L1182
  external JSFunction addVideoSource;

  /// Continuously decode barcodes from a [HTMLVideoElement].
  ///
  /// When a barcode is found, a callback function is called with the result.
  /// The callback function receives a [Result] and an exception object as arguments.
  ///
  /// See also: https://github.com/zxing-js/library/blob/master/src/browser/DecodeContinuouslyCallback.ts
  external JSFunction decodeContinuously;

  /// Whether the video stream is currently playing.
  ///
  /// This function takes a [HTMLVideoElement] as argument,
  /// and returns a [bool].
  ///
  /// See https://github.com/zxing-js/library/blob/master/src/browser/BrowserCodeReader.ts#L458
  external JSFunction isVideoPlaying;

  /// Prepare the video element for the barcode reader.
  ///
  /// This function takes a [HTMLVideoElement] as argument,
  /// and returns the same [HTMLVideoElement],
  /// after it was prepared for the barcode reader.
  ///
  /// See https://github.com/zxing-js/library/blob/master/src/browser/BrowserCodeReader.ts#L802
  external JSFunction prepareVideoElement;

  /// Reset the barcode reader to it's initial state,
  /// and stop any ongoing barcode decoding.
  ///
  /// This function takes no arguments and returns no result.
  ///
  /// See https://github.com/zxing-js/library/blob/master/src/browser/BrowserCodeReader.ts#L1104
  external JSFunction reset;

  /// Stop decoding barcodes.
  ///
  /// This function takes no arguments and returns no result.
  ///
  /// See https://github.com/zxing-js/library/blob/master/src/browser/BrowserCodeReader.ts#L396
  external JSFunction stopContinuousDecode;
}
