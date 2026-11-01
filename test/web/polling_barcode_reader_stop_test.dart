@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/web/polling_barcode_reader.dart';
import 'package:mobile_scanner/src/web/web_camera_utility.dart';
import 'package:web/web.dart' as web;

import 'utils/media_stream_test_utils.dart';

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

void main() {
  group('stopVideoStream', () {
    test('ends every track on the stream', () {
      final stream = createLiveVideoStream();
      final tracks = tracksOf(stream);

      expect(tracks, isNotEmpty, reason: 'the test stream must have tracks');
      expect(allLive(stream), isTrue, reason: 'a new stream starts live');

      stopVideoStream(stream);

      expect(
        allEnded(stream),
        isTrue,
        reason: 'stopping the stream must end every track',
      );
    });

    test('tolerates a null stream', () {
      expect(
        () => stopVideoStream(null),
        returnsNormally,
        reason: 'there is nothing to stop when no stream was acquired',
      );
    });
  });

  group('PollingBarcodeReader.stop', () {
    test('releases the camera by ending the video stream tracks', () async {
      final stream = createLiveVideoStream();
      final videoElement = web.HTMLVideoElement()..muted = true;
      final reader = _NoopPollingReader();

      await reader.start(
        testStartOptions,
        videoElement: videoElement,
        videoStream: stream,
      );

      expect(
        allLive(stream),
        isTrue,
        reason: 'the stream is live while the scanner is running',
      );

      await reader.stop();

      expect(
        allEnded(stream),
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
        testStartOptions,
        videoElement: videoElement,
        videoStream: stream,
      );
      expect(videoElement.srcObject, isNotNull);

      await reader.stop();

      expect(videoElement.srcObject, isNull);
    });

    test('is safe to call twice', () async {
      final stream = createLiveVideoStream();
      final reader = _NoopPollingReader();

      await reader.start(
        testStartOptions,
        videoElement: web.HTMLVideoElement()..muted = true,
        videoStream: stream,
      );

      await reader.stop();

      await expectLater(
        reader.stop(),
        completes,
        reason: 'stopping an already stopped reader must not throw',
      );

      expect(allEnded(stream), isTrue);
    });
  });
}
