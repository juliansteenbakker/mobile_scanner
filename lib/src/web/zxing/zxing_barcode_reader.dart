import 'dart:async';
import 'dart:js_interop';
import 'dart:ui';

import 'package:js/js.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/web/barcode_reader.dart';
import 'package:mobile_scanner/src/web/zxing/result.dart';
import 'package:mobile_scanner/src/web/zxing/zxing_browser_multi_format_reader.dart';
import 'package:web/web.dart' as web;

/// A barcode reader implementation that uses the ZXing library.
final class ZXingBarcodeReader extends BarcodeReader {
  ZXingBarcodeReader();

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
        return -1;
    }
  }

  /// Prepare the [web.MediaStream] for the barcode reader video input.
  ///
  /// This method requests permission to use the camera.
  Future<web.MediaStream?> _prepareMediaStream(
    CameraFacing cameraDirection,
  ) async {
    if (web.window.navigator.mediaDevices.isUndefinedOrNull) {
      return null;
    }

    final capabilities = web.window.navigator.mediaDevices.getSupportedConstraints();

    final web.MediaStreamConstraints constraints;

    if (capabilities.isUndefinedOrNull || !capabilities.facingMode) {
      constraints = web.MediaStreamConstraints(video: true.toJS);
    } else {
      final String facingMode = switch (cameraDirection) {
        CameraFacing.back => 'environment',
        CameraFacing.front => 'user',
      };

      constraints = web.MediaStreamConstraints(
        video: web.MediaTrackConstraintSet(
          facingMode: facingMode.toJS,
        ),
      );
    }

    final JSAny? mediaStream = await web.window.navigator.mediaDevices.getUserMedia(constraints).toDart;

    return mediaStream as web.MediaStream?;
  }

  /// Prepare the video element for the barcode reader.
  ///
  /// The given [videoElement] is attached to the DOM, by attaching it to the [containerElement].
  /// The camera video output is then attached to both the barcode reader (to detect barcodes),
  /// and the video element (to display the camera output).
  Future<void> _prepareVideoElement(
    web.HTMLVideoElement videoElement, {
    required CameraFacing cameraDirection,
    required web.HTMLElement containerElement,
  }) async {
    // Attach the video element to the DOM, through its parent container.
    containerElement.appendChild(videoElement);

    // Set up the camera output stream.
    // This will request permission to use the camera.
    final web.MediaStream? stream = await _prepareMediaStream(cameraDirection);

    if (stream != null) {
      final JSPromise? result = _reader?.attachStreamToVideo.callAsFunction(null, stream, videoElement) as JSPromise?;

      await result?.toDart;
    }
  }

  @override
  Stream<BarcodeCapture> detectBarcodes() {
    final controller = StreamController<BarcodeCapture>();

    controller.onListen = () {
      _reader?.decodeContinuously.callAsFunction(
        null,
        _reader?.videoElement,
        allowInterop((result, error) {
          if (!controller.isClosed && result != null) {
            final barcode = (result as Result).toBarcode;

            controller.add(
              BarcodeCapture(
                barcodes: [barcode],
              ),
            );
          }
        }).toJS,
      );
    };

    controller.onCancel = () async {
      _reader?.stopContinuousDecode.callAsFunction();
      _reader?.reset.callAsFunction();
      await controller.close();
    };

    return controller.stream;
  }

  @override
  Future<void> start(StartOptions options, {required web.HTMLElement containerElement}) async {
    final int detectionTimeoutMs = options.detectionTimeoutMs;
    final List<BarcodeFormat> formats = options.formats;

    if (formats.contains(BarcodeFormat.unknown)) {
      formats.removeWhere((element) => element == BarcodeFormat.unknown);
    }

    final Map<Object?, Object?>? hints;

    if (formats.isNotEmpty && !formats.contains(BarcodeFormat.all)) {
      // Set the formats hint.
      // See https://github.com/zxing-js/library/blob/master/src/core/DecodeHintType.ts#L45
      hints = {
        2: formats.map(getZXingBarcodeFormat).toList(),
      };
    } else {
      hints = null;
    }

    _reader = ZXingBrowserMultiFormatReader(hints.jsify(), detectionTimeoutMs);

    final web.HTMLVideoElement videoElement = web.document.createElement('video') as web.HTMLVideoElement;

    await _prepareVideoElement(
      videoElement,
      cameraDirection: options.cameraDirection,
      containerElement: containerElement,
    );
  }

  @override
  Future<void> stop() async {
    _reader?.stopContinuousDecode.callAsFunction();
    _reader?.reset.callAsFunction();
    _reader = null;
  }
}
