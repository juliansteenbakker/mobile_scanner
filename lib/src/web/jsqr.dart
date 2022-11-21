@JS()
library jsqr;

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:js/js.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/web/base.dart';

import 'media.dart';

@JS('jsQR')
external Code? jsQR(dynamic data, int? width, int? height);

@JS()
class Code {
  external String get data;

  external Uint8ClampedList get binaryData;
}


class JsQrCodeReader extends WebBarcodeReaderBase {
  // The video stream. Will be initialized later to see which camera needs to be used.
  MediaStream? _localStream;

  VideoElement video = VideoElement();

  DivElement vidDiv = DivElement();

  @override
  bool get isStarted => _localStream != null;

  @override
  int get videoWidth => video.videoWidth;
  @override
  int get videoHeight => video.videoHeight;

  @override
  Future<void> start({
    required String viewID,
    required CameraFacing cameraFacing,
  }) async {
    vidDiv.children = [video];
    // See https://github.com/flutter/flutter/issues/41563
    // ignore: UNDEFINED_PREFIXED_NAME, avoid_dynamic_calls
    ui.platformViewRegistry.registerViewFactory(
      viewID,
      (int id) => vidDiv
        ..style.width = '100%'
        ..style.height = '100%',
    );
    // Check if browser supports multiple camera's and set if supported
    final Map? capabilities =
        window.navigator.mediaDevices?.getSupportedConstraints();
    if (capabilities != null && capabilities['facingMode'] as bool) {
      final constraints = {
        'video': VideoOptions(
          facingMode:
              cameraFacing == CameraFacing.front ? 'user' : 'environment',
        )
      };

      _localStream =
          await window.navigator.mediaDevices?.getUserMedia(constraints);
    } else {
      _localStream = await window.navigator.mediaDevices
          ?.getUserMedia({'video': true});
    }

    video.srcObject = _localStream;

    // TODO: fix flash light. See https://github.com/dart-lang/sdk/issues/48533
    // final track = _localStream?.getVideoTracks();
    // if (track != null) {
    //   final imageCapture = html.ImageCapture(track.first);
    //   final photoCapabilities = await imageCapture.getPhotoCapabilities();
    // }

    // required to tell iOS safari we don't want fullscreen
    video.setAttribute('playsinline', 'true');
    await video.play();
  }

  @override
  Stream<String?> detectBarcodeContinuously() async* {
    yield* Stream.periodic(frameInterval, (_) {
      return _captureFrame(video);
    }).asyncMap((e) => e).map((event) => event?.data);
  }

  /// Captures a frame and analyzes it for QR codes
  Future<Code?> _captureFrame(VideoElement video) async {
    if (_localStream == null) return null;
    final canvas = CanvasElement(width: video.videoWidth, height: video.videoHeight);
    final ctx = canvas.context2D;

    ctx.drawImage(video, 0, 0);
    final imgData = ctx.getImageData(0, 0, canvas.width!, canvas.height!);

    final code = jsQR(imgData.data, canvas.width, canvas.height);
    return code;
  }

  @override
  Future<void> stop() async {
    try {
      // Stop the camera stream
      _localStream?.getTracks().forEach((track) {
        if (track.readyState == 'live') {
          track.stop();
        }
      });
    } catch (e) {
      debugPrint('Failed to stop stream: $e');
    }

    video.srcObject = null;
    _localStream = null;
  }
}
