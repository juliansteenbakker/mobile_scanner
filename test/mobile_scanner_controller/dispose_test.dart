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

  late FakeMobileScannerPlatform platform;

  setUp(() {
    platform = FakeMobileScannerPlatform();
    MobileScannerPlatform.instance = platform;
    MobileScannerController.resetPlatformSessionOwner();
  });

  group('dispose', () {
    test('disposing the only controller disposes the platform', () async {
      final controller = MobileScannerController(autoStart: false)..attach();

      await controller.start();
      await controller.dispose();

      expect(platform.disposeCalls, 1);
    });

    test(
      'disposing a controller that never started does not dispose the '
      'platform while another controller holds the camera session',
      () async {
        final first = MobileScannerController(autoStart: false)..attach();
        await first.start();

        final second = MobileScannerController(autoStart: false);
        await second.dispose();

        expect(platform.disposeCalls, 0);
        expect(platform.stopCalls, 0);
        expect(first.value.isRunning, isTrue);

        await first.dispose();

        expect(platform.disposeCalls, 1);
      },
    );

    test(
      'disposing a stopped controller does not dispose the platform '
      'while another controller holds the camera session',
      () async {
        final first = MobileScannerController(autoStart: false)..attach();
        await first.start();
        await first.stop();

        final second = MobileScannerController(autoStart: false)..attach();
        await second.start();

        await first.dispose();

        expect(platform.disposeCalls, 0);
        expect(second.value.isRunning, isTrue);

        await second.dispose();

        expect(platform.disposeCalls, 1);
      },
    );

    test(
      'disposing all controllers when none hold the camera session '
      'disposes the platform',
      () async {
        final controller = MobileScannerController(autoStart: false)..attach();

        await controller.start();
        await controller.stop();
        await controller.dispose();

        expect(platform.disposeCalls, 1);
      },
    );
  });
}

class FakeMobileScannerPlatform extends MobileScannerPlatform {
  int disposeCalls = 0;
  int stopCalls = 0;

  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream =>
      Stream.value(TorchState.unavailable);

  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) {
    return Future.value(
      const MobileScannerViewAttributes(
        cameraDirection: CameraFacing.back,
        currentTorchMode: TorchState.unavailable,
        size: Size(200, 200),
        numberOfCameras: 3,
        initialDeviceOrientation: DeviceOrientation.portraitUp,
      ),
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
