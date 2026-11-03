import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SingleSessionMobileScannerPlatform platform;

  setUp(() {
    platform = SingleSessionMobileScannerPlatform();
    MobileScannerPlatform.instance = platform;
    MobileScannerController.resetPlatformSessionOwner();
  });

  test('a start waits for the stop of another controller', () async {
    final first = MobileScannerController(autoStart: false)..attach();
    await first.start();

    final stopGate = Completer<void>();
    platform.stopGate = stopGate;

    final firstStop = first.stop();

    final second = MobileScannerController(autoStart: false)..attach();
    final secondStart = second.start();
    await pumpEventQueue();

    expect(platform.startCalls, 1, reason: 'the stop is still running');

    stopGate.complete();
    await Future.wait([firstStop, secondStart]);

    expect(second.value.error, isNull);
    expect(second.value.isRunning, isTrue);
    expect(MobileScannerController.platformSessionOwner, same(second));
  });

  test('a start waits for the pause of another controller', () async {
    final first = MobileScannerController(autoStart: false)..attach();
    await first.start();

    final pauseGate = Completer<void>();
    platform.pauseGate = pauseGate;

    final firstPause = first.pause();

    final second = MobileScannerController(autoStart: false)..attach();
    final secondStart = second.start();
    await pumpEventQueue();

    expect(platform.startCalls, 1, reason: 'the pause is still running');

    pauseGate.complete();
    await Future.wait([firstPause, secondStart]);

    expect(platform.pauseCalls, 1);
  });

  test('switching cameras does not interleave with the start of '
      'another controller', () async {
    final first = MobileScannerController(autoStart: false)..attach();
    await first.start();

    final stopGate = Completer<void>();
    platform.stopGate = stopGate;

    final switchCamera = first.switchCamera();

    final second = MobileScannerController(autoStart: false)..attach();
    final secondStart = second.start();
    await pumpEventQueue();

    expect(platform.startCalls, 1, reason: 'the switch is still stopping');

    stopGate.complete();
    await Future.wait([switchCamera, secondStart]);

    // The second start went first, so the restart of the switch finds the
    // session taken, as it would on a real device.
    expect(second.value.isRunning, isTrue);
    expect(
      first.value.error?.errorCode,
      MobileScannerErrorCode.controllerAlreadyInitialized,
    );
  });

  test('disposing a controller that waits for the lock does not stop '
      'the start of another controller', () async {
    final startGate = Completer<void>();
    platform.startGate = startGate;

    final first = MobileScannerController(autoStart: false)..attach();
    final firstStart = first.start();

    final second = MobileScannerController(autoStart: false)..attach();
    final secondStart = second.start();
    await second.dispose();

    expect(
      platform.stopCalls,
      0,
      reason: 'an early stop would abort the start of the first controller',
    );

    startGate.complete();
    await Future.wait([firstStart, secondStart]);

    expect(first.value.isRunning, isTrue);
    expect(MobileScannerController.platformSessionOwner, same(first));
  });
}

/// A platform that, like the native and web implementations,
/// rejects a start while a camera session is still open.
class SingleSessionMobileScannerPlatform extends MobileScannerPlatform {
  bool _hasSession = false;

  int startCalls = 0;
  int stopCalls = 0;
  int pauseCalls = 0;

  Completer<void>? startGate;
  Completer<void>? stopGate;
  Completer<void>? pauseGate;

  bool _isPaused = false;

  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream =>
      Stream.value(TorchState.unavailable);

  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    startCalls++;

    if (_hasSession && !_isPaused) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerAlreadyInitialized,
      );
    }

    _hasSession = true;
    _isPaused = false;

    await startGate?.future;

    return MobileScannerViewAttributes(
      cameraDirection: startOptions.cameraDirection,
      currentTorchMode: TorchState.unavailable,
      size: const Size(200, 200),
      numberOfCameras: 2,
      initialDeviceOrientation: DeviceOrientation.portraitUp,
    );
  }

  @override
  Future<void> stop() async {
    stopCalls++;

    // Like the web, the session is only cleared once the teardown is done.
    await stopGate?.future;
    _hasSession = false;
    _isPaused = false;
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    await pauseGate?.future;
    _isPaused = true;
  }

  @override
  Future<void> dispose() async {
    _hasSession = false;
    _isPaused = false;
  }
}
