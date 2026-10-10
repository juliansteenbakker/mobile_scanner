import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SlowStartMobileScannerPlatform platform;

  setUp(() {
    platform = SlowStartMobileScannerPlatform();
    MobileScannerPlatform.instance = platform;
    MobileScannerController.resetPlatformSessionOwner();
  });

  test(
    'a controller disposed while starting does not claim the camera session',
    () async {
      final controller = MobileScannerController(autoStart: false)..attach();

      final startFuture = controller.start();

      await controller.dispose();

      // The platform start only completes after the controller is gone,
      // which is the interleaving a user creates by dismissing the scanner
      // while the camera is still being acquired.
      platform.completeStart();
      await startFuture;

      // The disposed controller must not be left holding the platform camera
      // session: the next controller to dispose would then skip the platform
      // teardown, and the camera would stay live.
      final next = MobileScannerController(autoStart: false)..attach();

      await next.dispose();

      expect(platform.disposeCalls, 2);
    },
  );
}

class SlowStartMobileScannerPlatform extends MobileScannerPlatform {
  int disposeCalls = 0;
  int stopCalls = 0;

  final Completer<void> _startGate = Completer<void>();

  void completeStart() => _startGate.complete();

  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream =>
      Stream.value(TorchState.unavailable);

  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    await _startGate.future;

    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(200, 200),
      numberOfCameras: 1,
      initialDeviceOrientation: DeviceOrientation.portraitUp,
    );
  }

  @override
  Future<void> stop() {
    stopCalls++;
    return Future.value();
  }

  @override
  Future<void> dispose() {
    disposeCalls++;
    return Future.value();
  }
}
