@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/enums/web_barcode_reader.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/web/mobile_scanner_web.dart';
import 'package:web/web.dart' as web;

/// `HTMLCanvasElement.captureStream()` yields a real [web.MediaStream] backed
/// by a live video track, without prompting for camera permission.
extension type _CaptureStreamCanvas(JSObject _) implements JSObject {
  external web.MediaStream captureStream();
}

web.MediaStream createLiveVideoStream() {
  final canvas =
      web.HTMLCanvasElement()
        ..width = 32
        ..height = 32;
  canvas.context2D.fillRect(0, 0, 32, 32);

  return _CaptureStreamCanvas(canvas as JSObject).captureStream();
}

List<web.MediaStreamTrack> tracksOf(web.MediaStream stream) =>
    stream.getTracks().toDart;

bool allEnded(web.MediaStream stream) =>
    tracksOf(stream).every((track) => track.readyState == 'ended');

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

@JS('eval')
external JSAny? _jsEval(String code);

/// Replaces the global `BarcodeDetector` with one whose constructor throws, so
/// that a start fails at the point where it has already acquired the camera.
void _installFailingBarcodeDetector() {
  _jsEval('''
globalThis.__msOriginalBarcodeDetector = globalThis.BarcodeDetector;
globalThis.BarcodeDetector = function () {
  throw new Error("BarcodeDetector unavailable");
};
''');
}

void _restoreBarcodeDetector() {
  _jsEval('''
if ("__msOriginalBarcodeDetector" in globalThis) {
  if (globalThis.__msOriginalBarcodeDetector === undefined) {
    delete globalThis.BarcodeDetector;
  } else {
    globalThis.BarcodeDetector = globalThis.__msOriginalBarcodeDetector;
  }
  delete globalThis.__msOriginalBarcodeDetector;
}
''');
}

/// Replaces `navigator.mediaDevices.getUserMedia` with a stub whose promise
/// resolves only when the test says so, so that teardown can be interleaved
/// with an in-flight camera acquisition — the interleaving a user creates by
/// dismissing the scanner before the camera is ready.
class _GetUserMediaStub {
  _GetUserMediaStub() {
    _mediaDevices = web.window.navigator.mediaDevices as JSObject;
    _original = _mediaDevices.getProperty('getUserMedia'.toJS);

    _mediaDevices.setProperty(
      'getUserMedia'.toJS,
      ((JSAny? constraints) {
        callCount++;
        return _gate.future.toJS;
      }).toJS,
    );
  }

  late final JSObject _mediaDevices;
  late final JSAny? _original;

  final Completer<web.MediaStream> _gate = Completer<web.MediaStream>();

  int callCount = 0;

  /// Waits until the code under test has actually called `getUserMedia`.
  Future<void> awaitCall() async {
    while (callCount == 0) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Hands the caller a live stream, as the browser would.
  web.MediaStream resolve() {
    final stream = createLiveVideoStream();
    _gate.complete(stream);

    return stream;
  }

  void restore() {
    if (_original == null) {
      _mediaDevices.delete('getUserMedia'.toJS);
    } else {
      _mediaDevices.setProperty('getUserMedia'.toJS, _original);
    }
  }
}

void main() {
  late _GetUserMediaStub getUserMedia;

  setUp(() {
    web.window.localStorage.clear();
    getUserMedia = _GetUserMediaStub();
  });

  tearDown(() {
    getUserMedia.restore();
    _restoreBarcodeDetector();
  });

  group('MobileScannerWeb teardown during start', () {
    test('dispose() while acquiring the camera releases the stream', () async {
      final plugin =
          MobileScannerWeb()
            ..setWebBarcodeReader(WebBarcodeReader.barcodeDetector);

      final startFuture = plugin.start(_startOptions);

      await getUserMedia.awaitCall();

      // The scanner is dismissed while getUserMedia is still pending.
      await plugin.dispose();

      final stream = getUserMedia.resolve();

      await expectLater(
        startFuture,
        throwsA(isA<MobileScannerException>()),
        reason: 'a start that was torn down must not report a running camera',
      );

      expect(
        allEnded(stream),
        isTrue,
        reason: 'the camera acquired by the aborted start must be released',
      );
    });

    test('stop() while acquiring the camera releases the stream', () async {
      final plugin =
          MobileScannerWeb()
            ..setWebBarcodeReader(WebBarcodeReader.barcodeDetector);

      final startFuture = plugin.start(_startOptions);

      await getUserMedia.awaitCall();

      await plugin.stop();

      final stream = getUserMedia.resolve();

      await expectLater(startFuture, throwsA(isA<MobileScannerException>()));

      expect(allEnded(stream), isTrue);
    });
  });

  group('MobileScannerWeb start failure', () {
    test('a start that fails after acquiring the camera releases it', () async {
      _installFailingBarcodeDetector();

      final plugin =
          MobileScannerWeb()
            ..setWebBarcodeReader(WebBarcodeReader.barcodeDetector);

      final startFuture = plugin.start(_startOptions);

      await getUserMedia.awaitCall();

      final stream = getUserMedia.resolve();

      await expectLater(startFuture, throwsA(isA<MobileScannerException>()));

      expect(
        allEnded(stream),
        isTrue,
        reason: 'a failed start must not leave the camera running',
      );
    });
  });
}
