import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/web/barcode_reader.dart';
import 'package:mobile_scanner/src/web/javascript_map.dart';
import 'package:mobile_scanner/src/web/media_track_constraints_delegate.dart';
import 'package:mobile_scanner/src/web/media_track_extension.dart';
import 'package:mobile_scanner/src/web/zxing/result.dart';
import 'package:mobile_scanner/src/web/zxing/zxing_browser_multi_format_reader.dart';
import 'package:mobile_scanner/src/web/zxing/zxing_exception.dart';
import 'package:web/web.dart' as web;

/// A barcode reader implementation that uses the ZXing library.
final class ZXingBarcodeReader extends BarcodeReader {
  /// Construct a new [ZXingBarcodeReader] instance.
  ZXingBarcodeReader();

  /// ZXing reports an error with this message if the code could not be
  /// detected.
  @visibleForTesting
  static const String kNoCodeDetectedErrorMessage =
      'No MultiFormat Readers were able to detect the code.';

  /// The scan window as a normalized [Rect] (values in [0, 1]) relative to the
  /// camera texture. Barcodes whose bounding box does not overlap this rect are
  /// filtered out.
  Rect? _scanWindow;

  /// The listener for media track settings changes.
  void Function(web.MediaTrackSettings)? _onMediaTrackSettingsChanged;

  /// The internal media stream track constraints delegate.
  final MediaTrackConstraintsDelegate _mediaTrackConstraintsDelegate =
      const MediaTrackConstraintsDelegate();

  /// The internal barcode reader.
  ZXingBrowserMultiFormatReader? _reader;

  @override
  bool get isScanning => videoStream != null;

  @override
  Size get videoSize {
    final videoElement = _reader?.videoElement;

    if (videoElement == null) {
      return Size.zero;
    }

    return Size(
      videoElement.videoWidth.toDouble(),
      videoElement.videoHeight.toDouble(),
    );
  }

  @override
  web.MediaStream? get videoStream => _reader?.stream;

  @override
  String get scriptUrl => 'https://unpkg.com/@zxing/library@0.21.3';

  JSMap? _createReaderHints(List<BarcodeFormat> formats) {
    if (formats.isEmpty || formats.contains(BarcodeFormat.all)) {
      return null;
    }

    final hints =
        JSMap()
          // Set the formats hint.
          // See https://github.com/zxing-js/library/blob/master/src/core/DecodeHintType.ts#L45
          ..set(
            2.toJS,
            [for (final BarcodeFormat format in formats) format.toJS].toJS,
          );

    return hints;
  }

  /// Prepare the video element for the barcode reader.
  ///
  /// The given [videoElement] is assumed to already be attached to the DOM at
  /// this point. The camera video output is then attached to both the barcode
  /// reader (to detect barcodes), and the video element (to display the camera
  /// output).
  Future<void> _prepareVideoElement(
    web.HTMLVideoElement videoElement,
    web.MediaStream videoStream,
  ) async {
    final result =
        _reader?.attachStreamToVideo.callAsFunction(
              _reader,
              videoStream,
              videoElement,
            )
            as JSPromise?;

    await result?.toDart;

    final settings = _mediaTrackConstraintsDelegate.getSettings(videoStream);

    if (settings != null) {
      _onMediaTrackSettingsChanged?.call(settings);
    }
  }

  @override
  void updateScanWindow(Rect? window) {
    _scanWindow = window;
  }

  /// Returns true if the bounding box of [barcode] (in raw camera pixel
  /// coordinates) is fully contained within the current scan window.
  ///
  /// The scan window received from the Flutter layer is a normalized [Rect]
  /// (values in the range [0, 1]) relative to the camera texture, produced by
  /// [ScanWindowUtils.calculateScanWindowRelativeToTextureInPercentage].
  /// To match that space, the barcode corners are normalized by dividing by the
  /// video dimensions before comparing.
  ///
  /// This check must be performed on the **raw** (pre-mirror) barcode corners
  /// so that the coordinate spaces align.
  ///
  /// Always returns true when no scan window is set or dimensions are unknown.
  bool _isInsideScanWindow(Barcode barcode) {
    final window = _scanWindow;

    if (window == null) {
      return true;
    }

    final corners = barcode.corners;

    if (corners.length != 4) {
      return true;
    }

    final vw = videoSize.width;
    final vh = videoSize.height;

    if (vw <= 0 || vh <= 0) {
      return true;
    }

    // Normalize corner coordinates to [0, 1] in camera texture space.
    final minX = corners.map((c) => c.dx).reduce(math.min) / vw;
    final maxX = corners.map((c) => c.dx).reduce(math.max) / vw;
    final minY = corners.map((c) => c.dy).reduce(math.min) / vh;
    final maxY = corners.map((c) => c.dy).reduce(math.max) / vh;
    final barcodeRect = Rect.fromLTRB(minX, minY, maxX, maxY);

    // Accept only when the full barcode bounding box is inside the scan window.
    return barcodeRect.left >= window.left &&
        barcodeRect.top >= window.top &&
        barcodeRect.right <= window.right &&
        barcodeRect.bottom <= window.bottom;
  }

  /// Returns true if the video preview is currently mirrored horizontally,
  /// meaning barcode corner coordinates must be flipped to match.
  ///
  /// Must stay in sync with the logic in `_maybeFlipVideoPreview`.
  bool _shouldMirrorX() {
    final tracks = videoStream?.getVideoTracks().toDart;

    if (tracks == null || tracks.isEmpty) {
      return false;
    }

    final facingMode = tracks.first.getSettings().facingModeNullable?.toDart;

    // Mirror when facingMode is 'user' (front camera on mobile), or when
    // facingMode is null (desktop — cameras always face the user).
    return facingMode == 'user' || facingMode == null;
  }

  /// Returns a copy of [barcode] with all corner x-coordinates mirrored
  /// relative to [videoWidth].
  Barcode _mirrorBarcodeX(Barcode barcode, double videoWidth) {
    final corners = barcode.corners;

    if (corners.isEmpty) {
      return barcode;
    }

    // Mirror each x-coordinate.
    final mirrored =
        corners.map((c) => Offset(videoWidth - c.dx, c.dy)).toList();

    // Mirroring x reverses the clockwise winding order from
    // [TL, TR, BR, BL] to [TR_m, TL_m, BL_m, BR_m].
    // Swap TL↔TR and BL↔BR to restore [TL_m, TR_m, BR_m, BL_m].
    final reordered =
        mirrored.length == 4
            ? [mirrored[1], mirrored[0], mirrored[3], mirrored[2]]
            : mirrored;

    return Barcode(
      corners: reordered,
      format: barcode.format,
      displayValue: barcode.displayValue,
      // Populate deprecated rawBytes for backward compatibility.
      // ignore: deprecated_member_use_from_same_package
      rawBytes: barcode.rawBytes,
      rawDecodedBytes: barcode.rawDecodedBytes,
      rawValue: barcode.rawValue,
      size: barcode.size,
      type: barcode.type,
    );
  }

  @override
  Stream<BarcodeCapture> detectBarcodes() {
    final controller = StreamController<BarcodeCapture>();

    controller
      ..onListen = () {
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
              var barcode = result.toBarcode;

              // Check the scan window using raw camera coordinates (before
              // mirroring), because the scan window percentages are also in
              // raw camera space.
              if (!_isInsideScanWindow(barcode)) {
                return;
              }

              // Mirror corners for display after the scan window check.
              if (_shouldMirrorX()) {
                barcode = _mirrorBarcodeX(barcode, videoSize.width);
              }

              controller.add(
                BarcodeCapture(barcodes: [barcode], size: videoSize),
              );
            }
          }.toJS,
        );
      }
      // The onCancel() method of the controller is called
      // when the stream subscription returned by this method is cancelled in
      // `MobileScannerWeb.stop()`. This avoids both leaving the barcode scanner
      // running and a memory leak for the stream subscription.
      ..onCancel = () async {
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
    final detectionTimeoutMs = options.detectionTimeoutMs;
    final formats = <BarcodeFormat>[
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
  bool? get paused => _reader?.videoElement?.paused;

  @override
  void pause() => _reader?.videoElement?.pause();

  @override
  Future<void> resume() async {
    final result = _reader?.videoElement?.play();
    await result?.toDart;
  }

  @override
  Future<void> stop() async {
    _onMediaTrackSettingsChanged = null;
    _scanWindow = null;
    _reader?.stopContinuousDecode.callAsFunction(_reader);
    _reader?.reset.callAsFunction(_reader);
    _reader = null;
  }
}

extension on BarcodeFormat {
  /// Get the barcode format from the ZXing library.
  ///
  /// See https://github.com/zxing-js/library/blob/master/src/core/BarcodeFormat.ts
  JSNumber get toJS {
    final zxingFormat = switch (this) {
      BarcodeFormat.aztec => 0,
      BarcodeFormat.codabar => 1,
      BarcodeFormat.code39 => 2,
      BarcodeFormat.code93 => 3,
      BarcodeFormat.code128 => 4,
      BarcodeFormat.dataMatrix => 5,
      BarcodeFormat.ean8 => 6,
      BarcodeFormat.ean13 => 7,
      // ITF 2 of 5 is not supported by ZXing.
      BarcodeFormat.itf2of5 || BarcodeFormat.itf2of5WithChecksum => 8,
      BarcodeFormat.itf || BarcodeFormat.itf14 => 8,
      BarcodeFormat.pdf417 => 10,
      BarcodeFormat.qrCode => 11,
      BarcodeFormat.upcA => 14,
      BarcodeFormat.upcE => 15,
      BarcodeFormat.unknown || BarcodeFormat.all || _ => -1,
    };

    return zxingFormat.toJS;
  }
}
