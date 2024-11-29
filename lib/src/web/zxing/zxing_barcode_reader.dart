import 'dart:async';
import 'dart:js_interop';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/web/barcode_reader.dart';
import 'package:mobile_scanner/src/web/javascript_map.dart';
import 'package:mobile_scanner/src/web/media_track_constraints_delegate.dart';
import 'package:mobile_scanner/src/web/zxing/result.dart';
import 'package:mobile_scanner/src/web/zxing/zxing_browser_multi_format_reader.dart';
import 'package:mobile_scanner/src/web/zxing/zxing_exception.dart';
import 'package:web/web.dart' as web;

/// A barcode reader implementation that uses the ZXing library.
final class ZXingBarcodeReader extends BarcodeReader {
  ZXingBarcodeReader();

  /// ZXing reports an error with this message if the code could not be detected.
  @visibleForTesting
  static const String kNoCodeDetectedErrorMessage =
      'No MultiFormat Readers were able to detect the code.';

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
        for (final BarcodeFormat format in formats) format.toJS,
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
      _reader,
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
        _reader,
        _reader?.videoElement,
        (Result? result, ZXingException? error) {
          if (controller.isClosed) {
            return;
          }

          // Skip the event if no code was detected.
          if (error != null && error.message != kNoCodeDetectedErrorMessage) {
            controller.addError(MobileScannerBarcodeException(error.message));
            return;
          }

          if (result != null) {
            controller.add(
              BarcodeCapture(
                barcodes: [result.toBarcode],
                size: videoSize,
              ),
            );
          }
        }.toJS,
      );
    };

    // The onCancel() method of the controller is called
    // when the stream subscription returned by this method is cancelled in `MobileScannerWeb.stop()`.
    // This avoids both leaving the barcode scanner running and a memory leak for the stream subscription.
    controller.onCancel = () async {
      _reader?.stopContinuousDecode.callAsFunction(_reader);
      _reader?.reset.callAsFunction(_reader);
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
    final List<BarcodeFormat> formats = [
      for (final BarcodeFormat format in options.formats)
        if (format != BarcodeFormat.unknown) format,
    ];

    _reader = ZXingBrowserMultiFormatReader(
      _createReaderHints(formats),
      detectionTimeoutMs,
    );

    await _prepareVideoElement(videoElement, videoStream);
  }

  @override
  Future<void> stop() async {
    _onMediaTrackSettingsChanged = null;
    _reader?.stopContinuousDecode.callAsFunction(_reader);
    _reader?.reset.callAsFunction(_reader);
    _reader = null;
  }
}

extension on BarcodeFormat {
  /// Get the barcode format from the ZXing library.
  JSNumber get toJS {
    final int zxingFormat = switch (this) {
      BarcodeFormat.aztec => 0,
      BarcodeFormat.codabar => 1,
      BarcodeFormat.code39 => 2,
      BarcodeFormat.code93 => 3,
      BarcodeFormat.code128 => 4,
      BarcodeFormat.dataMatrix => 5,
      BarcodeFormat.ean8 => 6,
      BarcodeFormat.ean13 => 7,
      BarcodeFormat.itf => 8,
      BarcodeFormat.pdf417 => 10,
      BarcodeFormat.qrCode => 11,
      BarcodeFormat.upcA => 14,
      BarcodeFormat.upcE => 15,
      BarcodeFormat.unknown || BarcodeFormat.all || _ => -1,
    };

    return zxingFormat.toJS;
  }
}
