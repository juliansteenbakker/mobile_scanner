import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/web/base.dart';

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
      case 0:
        return BarcodeFormat.aztec;
      case 1:
        return BarcodeFormat.codebar;
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

extension ZXingBarcodeFormat on BarcodeFormat {
  int get zxingBarcodeFormat {
    switch (this) {
      case BarcodeFormat.aztec:
        return 0;
      case BarcodeFormat.codebar:
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

const zxingJsLibrary = JsLibrary(
  contextName: 'ZXing',
  url: 'https://unpkg.com/@zxing/library@0.19.1',
  usesRequireJs: true,
);

/// Barcode reader that uses zxing-js library.
class ZXingBarcodeReader extends WebBarcodeReaderBase
    with InternalStreamCreation, InternalTorchDetection {
  JsZXingBrowserMultiFormatReader? _reader;

  ZXingBarcodeReader({required super.videoContainer});

  @override
  bool get isStarted => localMediaStream != null;

  @override
  List<JsLibrary> get jsLibraries => [zxingJsLibrary];

  @override
  Future<void> start({
    required CameraFacing cameraFacing,
    List<BarcodeFormat>? formats,
    Duration? detectionTimeout,
  }) async {
    final JsMap? hints;
    if (formats != null && !formats.contains(BarcodeFormat.all)) {
      hints = JsMap();
      final zxingFormats =
          formats.map((e) => e.zxingBarcodeFormat).where((e) => e > 0).toList();
      // set hint DecodeHintType.POSSIBLE_FORMATS
      // https://github.com/zxing-js/library/blob/1e9ccb3b6b28d75b9eef866dba196d8937eb4449/src/core/DecodeHintType.ts#L28
      hints.set(2, zxingFormats);
    } else {
      hints = null;
    }
    if (detectionTimeout != null) {
      frameInterval = detectionTimeout;
    }
    _reader = JsZXingBrowserMultiFormatReader(
      hints,
      frameInterval.inMilliseconds,
    );
    videoContainer.children = [video];

    final stream = await initMediaStream(cameraFacing);

    prepareVideoElement(video);
    if (stream != null) {
      await attachStreamToVideo(stream, video);
    }
  }

  @override
  void prepareVideoElement(VideoElement videoSource) {
    _reader?.prepareVideoElement(videoSource);
  }

  @override
  Future<void> attachStreamToVideo(
    MediaStream stream,
    VideoElement videoSource,
  ) async {
    _reader?.addVideoSource(videoSource, stream);
    _reader?.videoElement = videoSource;
    _reader?.stream = stream;
    localMediaStream = stream;
    await videoSource.play();
  }

  @override
  Stream<Barcode?> detectBarcodeContinuously() {
    final controller = StreamController<Barcode?>();
    controller.onListen = () async {
      _reader?.decodeContinuously(
        video,
        allowInterop((result, error) {
          if (result != null) {
            controller.add(result.toBarcode());
          }
        }),
      );
    };
    controller.onCancel = () {
      _reader?.stopContinuousDecode();
    };
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    _reader?.reset();
    super.stop();
  }
}
