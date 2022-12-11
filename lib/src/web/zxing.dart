import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/web/base.dart';

@JS('Promise')
@staticInterop
class Promise<T> {}

@JS('ZXing.BrowserMultiFormatReader')
@staticInterop
class JsZXingBrowserMultiFormatReader {
  /// https://github.com/zxing-js/library/blob/1e9ccb3b6b28d75b9eef866dba196d8937eb4449/src/browser/BrowserMultiFormatReader.ts#L11
  external factory JsZXingBrowserMultiFormatReader(
    dynamic hints,
    int timeBetweenScansMillis,
  );
}

@JS()
@anonymous
abstract class Result {
  /// raw text encoded by the barcode
  external String get text;

  /// Returns raw bytes encoded by the barcode, if applicable, otherwise null
  external Uint8ClampedList? get rawBytes;

  /// Representing the format of the barcode that was decoded
  external int? format;
}

extension ResultExt on Result {
  Barcode toBarcode() {
    final rawBytes = this.rawBytes;
    return Barcode(
      rawValue: text,
      rawBytes: rawBytes != null ? Uint8List.fromList(rawBytes) : null,
      format: barcodeFormat,
    );
  }

  /// https://github.com/zxing-js/library/blob/1e9ccb3b6b28d75b9eef866dba196d8937eb4449/src/core/BarcodeFormat.ts#L28
  BarcodeFormat get barcodeFormat {
    switch (format) {
      case 1:
        return BarcodeFormat.aztec;
      case 2:
        return BarcodeFormat.codebar;
      case 3:
        return BarcodeFormat.code39;
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
      // case 9:
      //   return BarcodeFormat.maxicode;
      case 10:
        return BarcodeFormat.pdf417;
      case 11:
        return BarcodeFormat.qrCode;
      // case 12:
      //   return BarcodeFormat.rss14;
      // case 13:
      //   return BarcodeFormat.rssExp;
      case 14:
        return BarcodeFormat.upcA;
      case 15:
        return BarcodeFormat.upcE;
      default:
        return BarcodeFormat.unknown;
    }
  }
}

typedef BarcodeDetectionCallback = void Function(
  Result? result,
  dynamic error,
);

extension JsZXingBrowserMultiFormatReaderExt
    on JsZXingBrowserMultiFormatReader {
  external Promise<void> decodeFromVideoElementContinuously(
    VideoElement source,
    BarcodeDetectionCallback callbackFn,
  );

  /// Continuously decodes from video input
  external void decodeContinuously(
    VideoElement element,
    BarcodeDetectionCallback callbackFn,
  );

  external Promise<void> decodeFromStream(
    MediaStream stream,
    VideoElement videoSource,
    BarcodeDetectionCallback callbackFn,
  );

  external Promise<void> decodeFromConstraints(
    dynamic constraints,
    VideoElement videoSource,
    BarcodeDetectionCallback callbackFn,
  );

  external void stopContinuousDecode();

  external VideoElement prepareVideoElement(VideoElement videoSource);

  /// Defines what the [videoElement] src will be.
  external void addVideoSource(
    VideoElement videoElement,
    MediaStream stream,
  );

  external bool isVideoPlaying(VideoElement video);

  external void reset();

  /// The HTML video element, used to display the camera stream.
  external VideoElement? videoElement;

  /// The stream output from camera.
  external MediaStream? stream;
}

/// Barcode reader that uses zxing-js library.
///
/// Include zxing-js to your index.html file:
/// <script type="text/javascript" src="https://unpkg.com/@zxing/library@0.19.1"></script>
class ZXingBarcodeReader extends WebBarcodeReaderBase
    with InternalStreamCreation, InternalTorchDetection {
  late final JsZXingBrowserMultiFormatReader _reader =
      JsZXingBrowserMultiFormatReader(
    null,
    frameInterval.inMilliseconds,
  );

  ZXingBarcodeReader({required super.videoContainer});

  @override
  bool get isStarted => localMediaStream != null;

  @override
  Future<void> start({
    required CameraFacing cameraFacing,
  }) async {
    videoContainer.children = [video];

    final stream = await initMediaStream(cameraFacing);

    prepareVideoElement(video);
    if (stream != null) {
      await attachStreamToVideo(stream, video);
    }
  }

  @override
  void prepareVideoElement(VideoElement videoSource) {
    _reader.prepareVideoElement(videoSource);
  }

  @override
  Future<void> attachStreamToVideo(
    MediaStream stream,
    VideoElement videoSource,
  ) async {
    _reader.addVideoSource(videoSource, stream);
    _reader.videoElement = videoSource;
    _reader.stream = stream;
    localMediaStream = stream;
    await videoSource.play();
  }

  @override
  Stream<Barcode?> detectBarcodeContinuously() {
    final controller = StreamController<Barcode?>();
    controller.onListen = () async {
      _reader.decodeContinuously(
        video,
        allowInterop((result, error) {
          if (result != null) {
            controller.add(result.toBarcode());
          }
        }),
      );
    };
    controller.onCancel = () {
      _reader.stopContinuousDecode();
    };
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    _reader.reset();
    super.stop();
  }
}
