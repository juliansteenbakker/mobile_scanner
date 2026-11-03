import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart' show TestFailure;
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:web/web.dart' as web;

/// Start options for web tests, sized to match [createLiveVideoStream].
const testStartOptions = StartOptions(
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

extension type _CaptureStreamCanvas(web.HTMLCanvasElement _)
    implements web.HTMLCanvasElement {
  external web.MediaStream captureStream();
}

/// Creates a real [web.MediaStream] backed by a live video track.
///
/// `HTMLCanvasElement.captureStream()` does not prompt for camera permission,
/// which makes it the only way to observe track teardown in a headless
/// browser.
web.MediaStream createLiveVideoStream() {
  final canvas =
      web.HTMLCanvasElement()
        ..width = 32
        ..height = 32;
  // Draw once so the capture track produces a frame and goes live.
  canvas.context2D.fillRect(0, 0, 32, 32);

  return _CaptureStreamCanvas(canvas).captureStream();
}

/// The tracks of [stream].
List<web.MediaStreamTrack> tracksOf(web.MediaStream stream) =>
    stream.getTracks().toDart;

/// Whether [stream] has tracks and every one of them is still live.
bool allLive(web.MediaStream stream) => _allInState(stream, 'live');

/// Whether [stream] has tracks and every one of them has been stopped.
bool allEnded(web.MediaStream stream) => _allInState(stream, 'ended');

// A stream without tracks must not pass vacuously.
bool _allInState(web.MediaStream stream, String readyState) {
  final tracks = tracksOf(stream);

  return tracks.isNotEmpty &&
      tracks.every((track) => track.readyState == readyState);
}

extension type _StubbableMediaDevices(JSObject _) implements JSObject {
  external JSFunction getUserMedia;
}

/// Replaces `navigator.mediaDevices.getUserMedia` with a stub whose promise
/// resolves only when the test says so, so that teardown can be interleaved
/// with an in-flight camera acquisition, as when a user dismisses the scanner
/// before the camera is ready.
///
/// Call [restore] in `tearDown`.
class GetUserMediaStub {
  /// Install the stub.
  GetUserMediaStub() {
    _mediaDevices.getUserMedia =
        ((JSAny? constraints) {
          callCount++;
          if (!_called.isCompleted) {
            _called.complete();
          }
          return _gate.future.toJS;
        }).toJS;
  }

  final _mediaDevices = _StubbableMediaDevices(
    web.window.navigator.mediaDevices,
  );

  final Completer<web.MediaStream> _gate = Completer<web.MediaStream>();
  final Completer<void> _called = Completer<void>();

  /// How many times `getUserMedia` was called.
  int callCount = 0;

  /// Waits until the code under test has actually called `getUserMedia`.
  ///
  /// Fails the test instead of hanging if the call never comes.
  Future<void> awaitCall() => _called.future.timeout(
    const Duration(seconds: 5),
    onTimeout: () => throw TestFailure('getUserMedia was never called'),
  );

  /// Hands the caller a live stream, as the browser would.
  ///
  /// Called before `getUserMedia` is, the call resolves immediately.
  web.MediaStream resolve() {
    final stream = createLiveVideoStream();
    _gate.complete(stream);

    return stream;
  }

  /// Remove the stub, exposing the native `getUserMedia` again.
  void restore() {
    // The native method lives on `MediaDevices.prototype`; the stub is an own
    // property that shadows it.
    _mediaDevices.delete('getUserMedia'.toJS);
  }
}

extension type _StubbableGlobal(JSObject _) implements JSObject {
  @JS('BarcodeDetector')
  external JSFunction? barcodeDetector;
}

final _global = _StubbableGlobal(globalContext);

void _restoreBarcodeDetector(JSFunction? original) {
  if (original == null) {
    // The browser has no BarcodeDetector (e.g. Firefox): leave none behind,
    // rather than a `null` global that feature detection would trip over.
    _global.delete('BarcodeDetector'.toJS);
  } else {
    _global.barcodeDetector = original;
  }
}

/// Replaces the global `BarcodeDetector` with one whose constructor throws,
/// so that a start fails at the point where it has already acquired the
/// camera.
///
/// Call [restore] in `tearDown`.
class FailingBarcodeDetectorStub {
  /// Install the stub.
  FailingBarcodeDetectorStub() : _original = _global.barcodeDetector {
    _global.barcodeDetector = _throwingConstructor.toJS;
  }

  // Declared returning `JSAny?` rather than `Never`, which `toJS` rejects.
  static JSAny? _throwingConstructor() {
    throw StateError('BarcodeDetector unavailable');
  }

  final JSFunction? _original;

  /// Put the original `BarcodeDetector` back.
  void restore() => _restoreBarcodeDetector(_original);
}

/// Replaces the global `BarcodeDetector` with one that finds the same QR code
/// in every frame, so that barcode delivery can be observed without a camera.
///
/// Call [restore] in `tearDown`.
class DetectingBarcodeDetectorStub {
  /// Install the stub.
  DetectingBarcodeDetectorStub() : _original = _global.barcodeDetector {
    // `new` needs a real JS class, which a Dart function converted with `toJS`
    // is not.
    final functionConstructor = globalContext['Function']! as JSFunction;
    final createClass = functionConstructor.callAsConstructor<JSFunction>(
      '''
      return class {
        static async getSupportedFormats() { return ['qr_code']; }
        async detect() {
          return [{
            rawValue: '$rawValue',
            format: 'qr_code',
            cornerPoints: [
              {x: 0, y: 0}, {x: 8, y: 0}, {x: 8, y: 8}, {x: 0, y: 8},
            ],
          }];
        }
      };
      '''.toJS,
    );
    _global.barcodeDetector = createClass.callAsFunction() as JSFunction?;
  }

  /// The value of the QR code found in every frame.
  static const rawValue = 'detected';

  final JSFunction? _original;

  /// Put the original `BarcodeDetector` back.
  void restore() => _restoreBarcodeDetector(_original);
}

/// Mutes every media element before it plays, so that `play()` is not
/// rejected by the autoplay policy in a headless browser, where there is no
/// user gesture.
///
/// Call [restore] in `tearDown`.
class MutedAutoplayStub {
  /// Install the stub.
  MutedAutoplayStub() : _original = _prototype['play']! as JSFunction {
    final functionConstructor = globalContext['Function']! as JSFunction;
    final wrap = functionConstructor.callAsConstructor<JSFunction>(
      'play'.toJS,
      'return function() { this.muted = true; return play.call(this); };'.toJS,
    );
    _prototype['play'] = wrap.callAsFunction(null, _original);
  }

  static final _prototype =
      (globalContext['HTMLMediaElement']! as JSObject)['prototype']!
          as JSObject;

  final JSFunction _original;

  /// Put the original `play` back.
  void restore() => _prototype['play'] = _original;
}
