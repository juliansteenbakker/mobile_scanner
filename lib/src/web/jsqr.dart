@JS()
library jsqr;

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:mobile_scanner/src/web/base.dart';

@JS('jsQR')
external Code? jsQR(dynamic data, int? width, int? height);

@JS()
class Code {
  external String get data;

  external Uint8ClampedList get binaryData;
}


class JsQrCodeReader extends WebBarcodeReaderBase {
  // Timer used to capture frames to be analyzed
  final frameInterval = const Duration(milliseconds: 200);

  @override
  Stream<String?> detectBarcodeContinuously(VideoElement video) async* {
    yield* Stream.periodic(frameInterval, (_) {
      return _captureFrame(video);
    }).asyncMap((event) async => (await event)?.data);
  }

  /// Captures a frame and analyzes it for QR codes
  Future<Code?> _captureFrame(VideoElement video) async {
    final canvas = CanvasElement(width: video.videoWidth, height: video.videoHeight);
    final ctx = canvas.context2D;

    ctx.drawImage(video, 0, 0);
    final imgData = ctx.getImageData(0, 0, canvas.width!, canvas.height!);

    final code = jsQR(imgData.data, canvas.width, canvas.height);
    return code;
  }
}
