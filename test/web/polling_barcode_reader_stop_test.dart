@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/web/polling_barcode_reader.dart';
import 'package:mobile_scanner/src/web/web_camera_utility.dart';
import 'package:web/web.dart' as web;

/// `HTMLCanvasElement.captureStream()` yields a real [web.MediaStream] backed
/// by a live video track, without prompting for camera permission — the only
/// way to observe track teardown in a headless browser.
extension type _CaptureStreamCanvas(JSObject _) implements JSObject {
  external web.MediaStream captureStream();
}

web.MediaStream createLiveVideoStream() {
  final canvas = web.HTMLCanvasElement()
    ..width = 32
    ..height = 32;
  // Draw once so the capture track produces a frame and goes live.
  canvas.context2D.fillRect(0, 0, 32, 32);

  return _CaptureStreamCanvas(canvas as JSObject).captureStream();
}

List<web.MediaStreamTrack> tracksOf(web.MediaStream stream) =>
    stream.getTracks().toDart;

/// Minimal concrete reader: the video lifecycle under test lives entirely in
/// [PollingBarcodeReader], so the decoder hooks are no-ops.
final class _NoopPollingReader extends PollingBarcodeReader {
  int disposeDecoderCalls = 0;

  @override
  Future<List<Barcode>> decodeFrame(web.HTMLVideoElement video) async {
    return const [];
  }

  @override
  void disposeDecoder() => disposeDecoderCalls++;

  @override
  Future<void> prepareDecoder(StartOptions options) async {}
}

const _startOptions = StartOptions(
  cameraDirection: CameraFacing.back,
  cameraLensType: CameraLensType.any,
  cameraResolution: Size(32, 32),
  detectionSpeed: DetectionSpeed.noDuplicates,
  detectionTimeoutMs: 1000,
  formats: [BarcodeFormat.qrCode],
  returnImage: false,
  torchEnabled: false,
  invertImage: false,
  autoZoom: false,
  initialZoom: 1,
);

void main() {
  group('stopVideoStream', () {
    test('ends every track on the stream', () {
      final stream = createLiveVideoStream();
      final tracks = tracksOf(stream);

      expect(tracks, isNotEmpty);
      expect(tracks.every((t) => t.readyState == 'live'), isTrue);

      stopVideoStream(stream);

      expect(tracks.every((t) => t.readyState == 'ended'), isTrue);
    });

    test('tolerates a null stream', () {
      expect(() => stopVideoStream(null), returnsNormally);
    });
  });

  group('PollingBarcodeReader.stop', () {
    test('releases the camera by ending the video stream tracks', () async {
      final stream = createLiveVideoStream();
      final tracks = tracksOf(stream);
      final videoElement = web.HTMLVideoElement()..muted = true;
      final reader = _NoopPollingReader();

      await reader.start(
        _startOptions,
        videoElement: videoElement,
        videoStream: stream,
      );

      expect(
        tracks.every((t) => t.readyState == 'live'),
        isTrue,
        reason: 'the stream is live while the scanner is running',
      );

      await reader.stop();

      expect(
        tracks.every((t) => t.readyState == 'ended'),
        isTrue,
        reason: 'the OS camera indicator must go dark when the scanner closes',
      );
      expect(reader.isScanning, isFalse);
      expect(reader.disposeDecoderCalls, 1);
    });

    test('detaches the stream from the video element', () async {
      final stream = createLiveVideoStream();
      final videoElement = web.HTMLVideoElement()..muted = true;
      final reader = _NoopPollingReader();

      await reader.start(
        _startOptions,
        videoElement: videoElement,
        videoStream: stream,
      );
      expect(videoElement.srcObject, isNotNull);

      await reader.stop();

      expect(videoElement.srcObject, isNull);
    });

    test('is safe to call twice', () async {
      final stream = createLiveVideoStream();
      final tracks = tracksOf(stream);
      final reader = _NoopPollingReader();

      await reader.start(
        _startOptions,
        videoElement: web.HTMLVideoElement()..muted = true,
        videoStream: stream,
      );

      await reader.stop();
      await reader.stop();

      expect(tracks.every((t) => t.readyState == 'ended'), isTrue);
    });
  });
}
