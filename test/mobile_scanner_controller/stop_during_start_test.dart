import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const scanWindow = Rect.fromLTWH(0.25, 0.25, 0.5, 0.5);

  late FakeCameraSessionPlatform platform;

  setUp(() {
    platform = FakeCameraSessionPlatform();
    MobileScannerPlatform.instance = platform;
    MobileScannerController.resetPlatformSessionOwner();
  });

  // Create a controller that is attached to a scanner widget,
  // and dispose it at the end of the test.
  MobileScannerController createController() {
    final controller = MobileScannerController(autoStart: false)..attach();

    addTearDown(() async {
      // A failing test can leave platform calls on hold,
      // which would keep the dispose waiting for the session lock.
      platform.releaseHolds();
      await controller.dispose();
    });

    return controller;
  }

  group('stop while starting', () {
    test(
      'the next controller can start after a controller '
      'was stopped while starting',
      () async {
        final startGate = platform.hold('start');

        // The app passes in its own controller,
        // and stops it before the camera has started.
        final first = createController();
        final firstStart = first.start();
        final firstStop = first.stop();

        // Leaving the page does not dispose a controller that the app owns,
        // while the next page starts a new controller.
        final second = createController();
        final secondStart = second.start();

        startGate.complete();
        await Future.wait([firstStart, firstStop, secondStart]);

        expect(second.value.error, isNull);
        expect(second.value.isRunning, isTrue);
        expect(first.value.isRunning, isFalse);

        await second.dispose();

        expect(
          platform.isSessionOpen,
          isFalse,
          reason: 'the camera must not stay on after the scanner is closed',
        );
      },
    );

    test(
      'a start cancelled while it waits for a scanner widget '
      'that is never built completes without an error',
      () async {
        final controller = MobileScannerController(autoStart: false);
        addTearDown(controller.dispose);

        final start = controller.start();
        await controller.stop();

        await expectLater(start, completes);
        expect(controller.value.error, isNull);
        expect(platform.calls, isEmpty);
      },
    );

    test(
      'a start cancelled while it waits for the scanner widget '
      'does not wait for the camera of another controller',
      () async {
        final startGate = platform.hold('start');

        final other = createController();
        final otherStart = other.start();
        await pumpEventQueue();

        final controller = MobileScannerController(autoStart: false);
        addTearDown(() async {
          platform.releaseHolds();
          await controller.dispose();
        });

        var isStartCompleted = false;
        final start = controller.start().then((_) => isStartCompleted = true);
        final stop = controller.stop();

        controller.attach();
        await pumpEventQueue();

        expect(
          isStartCompleted,
          isTrue,
          reason: 'there is nothing left to wait for after the cancellation',
        );
        expect(controller.value.isStarting, isFalse);

        startGate.complete();
        await Future.wait([otherStart, start, stop]);

        expect(
          platform.count('start'),
          1,
          reason: 'the cancelled start must not reach the platform',
        );
        expect(controller.value.isRunning, isFalse);
        expect(other.value.isRunning, isTrue);
      },
    );

    test(
      'stopping a controller while the platform starts its camera '
      'lets the platform abort that start',
      () async {
        platform.abortsStartOnStop = true;
        final startGate = platform.hold('start');

        final controller = createController();
        final start = controller.start();
        await pumpEventQueue();

        final stop = controller.stop();

        startGate.complete();
        await Future.wait([start, stop]);

        expect(
          platform.sessionsOpened,
          0,
          reason: 'the platform must be told to stop before it has started',
        );
        expect(platform.isSessionOpen, isFalse);
      },
    );

    test(
      'a start that the platform aborts because of a stop '
      'does not report an error',
      () async {
        platform.abortsStartOnStop = true;
        final startGate = platform.hold('start');

        final controller = createController();
        final start = controller.start();
        await pumpEventQueue();

        final stop = controller.stop();

        startGate.complete();
        await Future.wait([start, stop]);

        expect(controller.value.error, isNull);
        expect(controller.value.isStarting, isFalse);
        expect(controller.value.isRunning, isFalse);

        await controller.start();

        expect(controller.value.error, isNull);
        expect(controller.value.isRunning, isTrue);
      },
    );

    test(
      'a controller whose start was cancelled by a stop '
      'ignores the events of the camera session',
      () async {
        final startGate = platform.hold('start');

        final controller = createController();
        final start = controller.start();
        await pumpEventQueue();

        final stop = controller.stop();

        startGate.complete();
        await Future.wait([start, stop]);

        final torchState = controller.value.torchState;
        final zoomScale = controller.value.zoomScale;

        platform.torchStates.add(TorchState.on);
        platform.zoomScales.add(0.5);
        await pumpEventQueue();

        expect(controller.value.torchState, torchState);
        expect(controller.value.zoomScale, zoomScale);
      },
    );

    test(
      'switching cameras again while the camera is restarting '
      'leaves the camera running',
      () async {
        final controller = createController();
        await controller.start();

        final restartGate = platform.hold('start');
        final firstSwitch = controller.switchCamera();
        await pumpEventQueue();

        // A double tap on the switch camera button.
        final secondSwitch = controller.switchCamera();
        await pumpEventQueue();

        restartGate.complete();
        await Future.wait([firstSwitch, secondSwitch]);

        expect(controller.value.error, isNull);
        expect(controller.value.isRunning, isTrue);
        expect(platform.isSessionOpen, isTrue);
      },
    );

    test(
      'stopping a controller that waits for the camera session '
      'does not interrupt the start of another controller',
      () async {
        final startGate = platform.hold('start');

        final first = createController();
        final firstStart = first.start();
        await pumpEventQueue();

        // The second start waits until the first one has completed.
        final second = createController();
        final secondStart = second.start();
        final secondStop = second.stop();
        await pumpEventQueue();

        expect(
          platform.calls,
          ['start'],
          reason:
              'nothing else may reach the platform '
              'while the first controller is starting',
        );

        startGate.complete();
        await Future.wait([firstStart, secondStart, secondStop]);

        expect(first.value.error, isNull);
        expect(first.value.isRunning, isTrue);
        expect(second.value.isRunning, isFalse);
        expect(
          platform.isSessionOpen,
          isTrue,
          reason: 'the camera of the first controller must keep running',
        );
        expect(
          platform.count('start'),
          1,
          reason: 'the cancelled start must not reach the platform',
        );
      },
    );
  });

  group('start after a stop that cancelled a pending start', () {
    test('starts the camera once the cancelled start has completed', () async {
      final startGate = platform.hold('start');

      final controller = createController();
      final start = controller.start();
      await pumpEventQueue();

      // Let the platform start complete only after the stop,
      // even if stop() waits for it.
      final release = Future<void>(startGate.complete);
      await controller.stop();
      final restart = controller.start();

      await Future.wait([start, release, restart]);

      expect(controller.value.error, isNull);
      expect(controller.value.isRunning, isTrue);
      expect(platform.isSessionOpen, isTrue);
    });

    test(
      'a start, stop, start and stop while the first start is pending '
      'leave the camera stopped',
      () async {
        final startGate = platform.hold('start');

        final controller = createController();
        final firstStart = controller.start();
        await pumpEventQueue();

        final firstStop = controller.stop();
        final secondStart = controller.start();
        await pumpEventQueue();
        final secondStop = controller.stop();

        startGate.complete();
        await Future.wait([firstStart, firstStop, secondStart, secondStop]);
        await pumpEventQueue();

        expect(controller.value.isRunning, isFalse);
        expect(controller.value.isStarting, isFalse);
        expect(platform.isSessionOpen, isFalse);
      },
    );

    test(
      'completes without an error when the controller is disposed '
      'before the cancelled start has completed',
      () async {
        final startGate = platform.hold('start');

        final controller = createController();
        final start = controller.start();
        await pumpEventQueue();

        final stop = controller.stop();
        final restart = controller.start();
        final dispose = controller.dispose();

        startGate.complete();
        await Future.wait([start, stop, restart, dispose]);

        expect(platform.isSessionOpen, isFalse);
      },
    );
  });

  group('MobileScanner widget', () {
    testWidgets(
      'restarts the camera when the app is quickly inactive and resumed '
      'while the camera is starting',
      (tester) async {
        addTearDown(platform.releaseHolds);

        // The scanner owns its controller,
        // and follows the app lifecycle state.
        await tester.pumpWidget(const MaterialApp(home: MobileScanner()));
        await tester.pump();

        expect(platform.isSessionOpen, isTrue);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();

        expect(platform.isSessionOpen, isFalse);

        final startGate = platform.hold('start');

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        // The app flickers to inactive and back while the camera is starting.
        tester.binding
          ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
          ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        startGate.complete();
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(
          platform.isSessionOpen,
          isTrue,
          reason: 'the app ended resumed, so the camera must be running',
        );

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'shows a running camera after the page with an app-owned controller '
      'was closed and opened again while the camera was starting',
      (tester) async {
        addTearDown(platform.releaseHolds);

        final controller = MobileScannerController();
        addTearDown(controller.dispose);

        final startGate = platform.hold('start');

        // Open the page, which starts the camera.
        await tester.pumpWidget(
          MaterialApp(home: MobileScanner(controller: controller)),
        );
        await tester.pump();

        // Close the page before the camera has started,
        // which stops the camera.
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pump();

        // Open the page again with the same controller.
        await tester.pumpWidget(
          MaterialApp(home: MobileScanner(controller: controller)),
        );
        await tester.pump();

        startGate.complete();
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(controller.value.error, isNull);
        expect(controller.value.isRunning, isTrue);
        expect(platform.isSessionOpen, isTrue);

        await tester.pumpWidget(const SizedBox());
      },
    );
  });

  group('stop without a pending start', () {
    test('does not call the platform for a controller '
        'that was never started', () async {
      final controller = createController();

      await controller.stop();

      expect(platform.calls, isEmpty);
    });

    test('does not stop the camera of another controller', () async {
      final running = createController();
      await running.start();

      final idle = createController();
      await idle.stop();

      expect(platform.count('stop'), 0);
      expect(platform.isSessionOpen, isTrue);
      expect(running.value.isRunning, isTrue);
    });

    test('does not call the platform again for a stopped controller', () async {
      final controller = createController();
      await controller.start();
      await controller.stop();

      final callsAfterStop = List.of(platform.calls);

      await controller.stop();

      expect(platform.calls, callsAfterStop);
    });
  });

  group('stop during a pending start', () {
    test('completes once the camera has been released', () async {
      final startGate = platform.hold('start');

      final controller = createController();
      final start = controller.start();
      await pumpEventQueue();

      var isStopCompleted = false;
      final stop = controller.stop().then((_) => isStopCompleted = true);
      await pumpEventQueue();

      expect(
        isStopCompleted,
        isFalse,
        reason: 'the camera is still starting',
      );

      startGate.complete();
      await Future.wait([start, stop]);

      expect(platform.calls.last, 'stop done');
      expect(platform.isSessionOpen, isFalse);
    });

    test('reports an error of the platform stop', () async {
      final startGate = platform.hold('start');

      final controller = createController();
      final start = controller.start();
      await pumpEventQueue();

      platform.stopError = PlatformException(code: 'stop');
      final stop = controller.stop();

      startGate.complete();
      await start;

      await expectLater(stop, throwsA(isA<PlatformException>()));
    });

    test('still reports an error of the start', () async {
      platform.startError = const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
      final startGate = platform.hold('start');

      final controller = createController();
      final start = controller.start();
      await pumpEventQueue();

      final stop = controller.stop();

      startGate.complete();
      await Future.wait([start, stop]);

      expect(
        controller.value.error?.errorCode,
        MobileScannerErrorCode.permissionDenied,
      );
      expect(controller.value.hasCameraPermission, isFalse);
    });

    test('lets two waiting starts start the camera once', () async {
      final startGate = platform.hold('start');

      final controller = createController();
      final firstStart = controller.start();
      await pumpEventQueue();

      final stop = controller.stop();
      final secondStart = controller.start();
      final thirdStart = controller.start();

      startGate.complete();
      await Future.wait([firstStart, stop, secondStart, thirdStart]);

      expect(controller.value.error, isNull);
      expect(controller.value.isRunning, isTrue);
      expect(platform.sessionsOpened, 2);
    });
  });

  group('MobileScanner widget lifecycle', () {
    testWidgets('does not cancel a start when the app becomes inactive', (
      tester,
    ) async {
      addTearDown(platform.releaseHolds);

      await tester.pumpWidget(const MaterialApp(home: MobileScanner()));
      await tester.pump();

      // Restart the camera, so the permission is known.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      final startGate = platform.hold('start');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // A permission prompt takes the focus while the camera starts.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      startGate.complete();
      await tester.pump();
      await tester.pump();

      expect(platform.count('start'), 2);
      expect(platform.count('stop'), 1);
      expect(platform.isSessionOpen, isTrue);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('updateScanWindow', () {
    test('does not change the camera session of another controller', () async {
      final first = createController();
      await first.start();
      await first.stop();

      final second = createController();
      await second.start();

      await first.updateScanWindow(scanWindow);

      expect(platform.count('updateScanWindow'), 0);

      await second.stop();
      await first.start();

      expect(
        platform.count('updateScanWindow'),
        1,
        reason: 'the scan window is applied once the camera is started again',
      );
    });
  });
}

/// A fake platform with a single camera session, like the native platforms.
///
/// It records the calls that change the camera session,
/// and can hold any of them, to make two controllers race each other.
class FakeCameraSessionPlatform extends MobileScannerPlatform {
  /// The calls that change the camera session, in the order they were made.
  ///
  /// A call is recorded by its method name when it is made,
  /// and again with a ` done` suffix once it has completed.
  final List<String> calls = <String>[];

  /// The most calls that were in progress at the same time.
  int maxCallsInProgress = 0;
  int _callsInProgress = 0;

  final Map<String, Completer<void>> _pendingHolds = {};
  final List<Completer<void>> _holds = [];

  bool _isSessionOpen = false;
  bool _isPaused = false;
  int _stopCalls = 0;

  /// Whether a camera session is open, i.e. started and not yet released.
  bool get isSessionOpen => _isSessionOpen;

  /// The number of times that a start acquired the camera.
  int sessionsOpened = 0;

  /// Whether a stop that is made while a start is in progress aborts that
  /// start, which then fails without acquiring the camera, like on the web.
  bool abortsStartOnStop = false;

  /// If set, [start] throws this error.
  Exception? startError;

  /// If set, [stop] throws this error.
  Exception? stopError;

  /// The torch state events of the camera session.
  final StreamController<TorchState> torchStates = StreamController.broadcast();

  /// The zoom scale events of the camera session.
  final StreamController<double> zoomScales = StreamController.broadcast();

  /// Hold the next call to [method] until the returned completer completes.
  Completer<void> hold(String method) {
    final hold = Completer<void>();
    _pendingHolds[method] = hold;
    _holds.add(hold);

    return hold;
  }

  /// Complete every hold, so that no call stays in progress.
  void releaseHolds() {
    for (final hold in _holds) {
      if (!hold.isCompleted) {
        hold.complete();
      }
    }
  }

  /// The number of times that [method] was called.
  int count(String method) => calls.where((call) => call == method).length;

  Future<T> _record<T>(String method, T Function() complete) async {
    calls.add(method);
    _callsInProgress++;
    maxCallsInProgress = math.max(maxCallsInProgress, _callsInProgress);

    try {
      await _pendingHolds.remove(method)?.future;

      return complete();
    } finally {
      _callsInProgress--;
      calls.add('$method done');
    }
  }

  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream => torchStates.stream;

  @override
  Stream<double> get zoomScaleStateStream => zoomScales.stream;

  @override
  Widget buildCameraView() => const SizedBox();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) {
    final stopCallsBeforeStart = _stopCalls;

    return _record('start', () {
      if (startError case final error?) {
        throw error;
      }

      if (abortsStartOnStop && _stopCalls != stopCallsBeforeStart) {
        throw const MobileScannerException(
          errorCode: MobileScannerErrorCode.controllerDisposed,
          errorDetails: MobileScannerErrorDetails(
            message: 'The scanner was stopped while the camera was starting.',
          ),
        );
      }

      // Like the native platforms, refuse to start a second camera session.
      if (_isSessionOpen && !_isPaused) {
        throw MobileScannerException(
          errorCode: MobileScannerErrorCode.controllerAlreadyInitialized,
          errorDetails: MobileScannerErrorDetails(
            message:
                MobileScannerErrorCode.controllerAlreadyInitialized.message,
          ),
        );
      }

      _isSessionOpen = true;
      _isPaused = false;
      sessionsOpened++;

      return MobileScannerViewAttributes(
        cameraDirection: startOptions.cameraDirection,
        currentTorchMode: TorchState.unavailable,
        size: const Size(200, 200),
        numberOfCameras: 2,
        initialDeviceOrientation: DeviceOrientation.portraitUp,
      );
    });
  }

  @override
  Future<void> stop() {
    _stopCalls++;

    return _record('stop', () {
      if (stopError case final error?) {
        throw error;
      }

      _isSessionOpen = false;
      _isPaused = false;
    });
  }

  @override
  Future<void> pause() {
    return _record('pause', () {
      _isPaused = _isSessionOpen;
    });
  }

  @override
  Future<void> updateScanWindow(Rect? window) {
    return _record('updateScanWindow', () {});
  }

  @override
  Future<void> dispose() {
    return _record('dispose', () {
      _isSessionOpen = false;
      _isPaused = false;
    });
  }
}
