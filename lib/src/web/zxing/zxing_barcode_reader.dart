import 'dart:async';
import 'dart:js_interop';
import 'dart:ui';

import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/web/barcode_reader.dart';
import 'package:mobile_scanner/src/web/javascript_map.dart';
import 'package:mobile_scanner/src/web/media_track_constraints_delegate.dart';
import 'package:mobile_scanner/src/web/zxing/result.dart';
import 'package:mobile_scanner/src/web/zxing/zxing_browser_multi_format_reader.dart';
import 'package:web/web.dart' as web;

// TODO: remove the JSAny casts once upgraded to a package:web version that restores "implements JSAny"

/// A barcode reader implementation that uses the ZXing library.
final class ZXingBarcodeReader extends BarcodeReader {
  ZXingBarcodeReader();

  /// The listener for media track settings changes.
  void Function(web.MediaTrackSettings)? _onMediaTrackSettingsChanged;

  /// The internal media stream track constraints delegate.
  final MediaTrackConstraintsDelegate _mediaTrackConstraintsDelegate =
      const MediaTrackConstraintsDelegate();

  /// The internal barcode reader.
  ZXingBrowserMultiFormatReader? _reader;

  @override
  bool get isScanning => _reader?.stream != null;

  @override
  Size get videoSize {
    final web.HTMLVideoElement? videoElement = _reader?.videoElement;

    if (videoElement == null) {
      return Size.zero;
    }

    return Size(
      videoElement.videoWidth.toDouble(),
      videoElement.videoHeight.toDouble(),
    );
  }

  @override
  String get scriptUrl => 'https://unpkg.com/@zxing/library@0.19.1';

  /// Get the barcode format from the ZXing library, for the given [format].
  static int getZXingBarcodeFormat(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.aztec:
        return 0;
      case BarcodeFormat.codabar:
        return 1;
      case BarcodeFormat.code39:
        return 2;
      case BarcodeFormat.code93:
        return 3;
      case BarcodeFormat.code128:
        return 4;
      case BarcodeFormat.dataMatrix:
        return 5;
      case BarcodeFormat.ean8:
        return 6;
      case BarcodeFormat.ean13:
        return 7;
      case BarcodeFormat.itf:
        return 8;
      case BarcodeFormat.pdf417:
        return 10;
      case BarcodeFormat.qrCode:
        return 11;
      case BarcodeFormat.upcA:
        return 14;
      case BarcodeFormat.upcE:
        return 15;
      case BarcodeFormat.unknown:
      case BarcodeFormat.all:
      default:
        return -1;
    }
  }

  JSMap? _createReaderHints(List<BarcodeFormat> formats) {
    if (formats.isEmpty || formats.contains(BarcodeFormat.all)) {
      return null;
    }

    final JSMap hints = JSMap();

    // Set the formats hint.
    // See https://github.com/zxing-js/library/blob/master/src/core/DecodeHintType.ts#L45
    hints.set(
      2.toJS,
      [
        for (final BarcodeFormat format in formats)
          getZXingBarcodeFormat(format).toJS,
      ].toJS,
    );

    return hints;
  }

  /// Prepare the video element for the barcode reader.
  ///
  /// The given [videoElement] is assumed to already be attached to the DOM at this point.
  /// The camera video output is then attached to both the barcode reader (to detect barcodes),
  /// and the video element (to display the camera output).
  Future<void> _prepareVideoElement(
    web.HTMLVideoElement videoElement,
    web.MediaStream videoStream,
  ) async {
    final JSPromise? result = _reader?.attachStreamToVideo.callAsFunction(
      _reader as JSAny?,
      videoStream,
      videoElement,
    ) as JSPromise?;

    await result?.toDart;

    final web.MediaTrackSettings? settings =
        _mediaTrackConstraintsDelegate.getSettings(videoStream);

    if (settings != null) {
      _onMediaTrackSettingsChanged?.call(settings);
    }
  }

  @override
  Stream<BarcodeCapture> detectBarcodes() {
    final controller = StreamController<BarcodeCapture>();

    controller.onListen = () {
      _reader?.decodeContinuously.callAsFunction(
        _reader as JSAny?,
        _reader?.videoElement,
        (Result? result, JSAny? error) {
          if (controller.isClosed || result == null) {
            return;
          }

          controller.add(
            BarcodeCapture(
              barcodes: [result.toBarcode],
            ),
          );
        }.toJS,
      );
    };

    // The onCancel() method of the controller is called
    // when the stream subscription returned by this method is cancelled in `MobileScannerWeb.stop()`.
    // This avoids both leaving the barcode scanner running and a memory leak for the stream subscription.
    controller.onCancel = () async {
      _reader?.stopContinuousDecode.callAsFunction(_reader as JSAny?);
      _reader?.reset.callAsFunction(_reader as JSAny?);
      await controller.close();
    };

    return controller.stream;
  }

  @override
  void setMediaTrackSettingsListener(
    void Function(web.MediaTrackSettings) listener,
  ) {
    _onMediaTrackSettingsChanged ??= listener;
  }

  @override
  Future<void> start(
    StartOptions options, {
    required web.HTMLVideoElement videoElement,
    required web.MediaStream videoStream,
  }) async {
    final int detectionTimeoutMs = options.detectionTimeoutMs;
    final List<BarcodeFormat> formats = options.formats;

    if (formats.contains(BarcodeFormat.unknown)) {
      formats.removeWhere((element) => element == BarcodeFormat.unknown);
    }

    _reader = ZXingBrowserMultiFormatReader(
      _createReaderHints(formats),
      detectionTimeoutMs.toJS,
    );

    await _prepareVideoElement(videoElement, videoStream);
  }

  @override
  Future<void> stop() async {
    _onMediaTrackSettingsChanged = null;
    _reader?.stopContinuousDecode.callAsFunction(_reader as JSAny?);
    _reader?.reset.callAsFunction(_reader as JSAny?);
    _reader = null;
  }
}
