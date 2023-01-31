@JS()
library jsqr;

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/web/base.dart';

@JS('jsQR')
external Code? jsQR(dynamic data, int? width, int? height);

@JS()
class Code {
  external String get data;

  external Uint8ClampedList get binaryData;
}

const jsqrLibrary = JsLibrary(
  contextName: 'jsQR',
  url: 'https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.min.js',
  usesRequireJs: true,
);

/// Barcode reader that uses jsQR library.
/// jsQR supports only QR codes format.
class JsQrCodeReader extends WebBarcodeReaderBase
    with InternalStreamCreation, InternalTorchDetection {
  JsQrCodeReader({required super.videoContainer});

  @override
  bool get isStarted => localMediaStream != null;

  @override
  List<JsLibrary> get jsLibraries => [jsqrLibrary];

  @override
  Future<void> start({
    required CameraFacing cameraFacing,
    List<BarcodeFormat>? formats,
    Duration? detectionTimeout,
  }) async {
    videoContainer.children = [video];

    if (detectionTimeout != null) {
      frameInterval = detectionTimeout;
    }

    final stream = await initMediaStream(cameraFacing);

    prepareVideoElement(video);
    if (stream != null) {
      await attachStreamToVideo(stream, video);
    }
  }

  @override
  void prepareVideoElement(VideoElement videoSource) {
    // required to tell iOS safari we don't want fullscreen
    videoSource.setAttribute('playsinline', 'true');
  }

  @override
  Future<void> attachStreamToVideo(
    MediaStream stream,
    VideoElement videoSource,
  ) async {
    localMediaStream = stream;
    videoSource.srcObject = stream;
    await videoSource.play();
  }

  @override
  Stream<Barcode?> detectBarcodeContinuously() async* {
    yield* Stream.periodic(frameInterval, (_) {
      return _captureFrame(video);
    }).asyncMap((event) async {
      final code = await event;
      if (code == null) {
        return null;
      }
      return Barcode(
        rawValue: code.data,
        rawBytes: Uint8List.fromList(code.binaryData),
        format: BarcodeFormat.qrCode,
      );
    });
  }

  /// Captures a frame and analyzes it for QR codes
  Future<Code?> _captureFrame(VideoElement video) async {
    if (localMediaStream == null) return null;
    final canvas =
        CanvasElement(width: video.videoWidth, height: video.videoHeight);
    final ctx = canvas.context2D;

    ctx.drawImage(video, 0, 0);
    final imgData = ctx.getImageData(0, 0, canvas.width!, canvas.height!);

    final code = jsQR(imgData.data, canvas.width, canvas.height);
    return code;
  }
}
