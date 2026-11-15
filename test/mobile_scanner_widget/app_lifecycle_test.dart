import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(MobileScannerController.resetPlatformSessionOwner);

  // See https://github.com/juliansteenbakker/mobile_scanner/issues/1863
  testWidgets('resuming while a restart is pending does not throw', (
    tester,
  ) async {
    final fakePlatform = GatedStartMobileScannerPlatform();

    MobileScannerPlatform.instance = fakePlatform;

    // The lifecycle state is global to the test binding.
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MobileScanner())),
    );
    await tester.pumpAndSettle();

    expect(fakePlatform.startCalls, 1);

    // Stop the running camera, then begin a restart that stays pending.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(fakePlatform.stopCalls, 1);

    fakePlatform.startGate = Completer<void>();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(fakePlatform.startCalls, 2);

    // The camera is not running yet, so this stop is ignored.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(fakePlatform.stopCalls, 1);

    // Resuming again while the restart is pending must not raise
    // an unhandled controllerInitializing error.
    final errors = <Object>[];
    runZonedGuarded(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
      (error, _) => errors.add(error),
    );
    await tester.pump();

    expect(errors, isEmpty);

    fakePlatform.startGate!.complete();
    await tester.pumpAndSettle();

    expect(fakePlatform.startCalls, 2);

    // The pending restart completed, so the camera is running and can stop.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(fakePlatform.stopCalls, 2);
  });
}

class GatedStartMobileScannerPlatform extends MobileScannerPlatform {
  int startCalls = 0;
  int stopCalls = 0;

  /// If set, calls to [start] wait until this gate completes.
  Completer<void>? startGate;

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

    await startGate?.future;

    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(200, 200),
      numberOfCameras: 1,
    );
  }

  @override
  Future<void> stop() {
    stopCalls++;
    return Future.value();
  }

  @override
  Widget buildCameraView() {
    return const SizedBox.square(dimension: 100);
  }

  @override
  Future<void> dispose() => Future.value();
}
