import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';

// TODO(navaronbracke): add more tests for switchCamera
// - toggle direction, select camera, walk lenses

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('switchCamera', () {
    test('throws when controller is not initialized', () async {
      MobileScannerPlatform.instance = FakeMobileScannerPlatform();

      final controller = MobileScannerController(autoStart: false);

      expect(
        controller.switchCamera(),
        throwsA(
          isA<MobileScannerException>().having(
            (e) => e.errorCode,
            'errorCode',
            MobileScannerErrorCode.controllerUninitialized,
          ),
        ),
      );
    });

    test(
      'throws when controller is not initialized and then disposed',
      () async {
        MobileScannerPlatform.instance = FakeMobileScannerPlatform();

        final controller = MobileScannerController(autoStart: false);

        await controller.dispose();

        expect(
          controller.switchCamera(),
          throwsA(
            isA<MobileScannerException>().having(
              (e) => e.errorCode,
              'errorCode',
              MobileScannerErrorCode.controllerDisposed,
            ),
          ),
        );
      },
    );

    test('throws when controller is started and then disposed', () async {
      MobileScannerPlatform.instance = FakeMobileScannerPlatform();

      final controller = MobileScannerController(autoStart: false)..attach();
      await controller.start();
      await controller.dispose();

      expect(
        controller.switchCamera(),
        throwsA(
          isA<MobileScannerException>().having(
            (e) => e.errorCode,
            'errorCode',
            MobileScannerErrorCode.controllerDisposed,
          ),
        ),
      );
    });
  });
}

class FakeMobileScannerPlatform extends MobileScannerPlatform {
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
  Future<Set<CameraLensType>> getSupportedLenses({
    CameraFacing? facing,
  }) {
    return Future.value({
      CameraLensType.normal,
      CameraLensType.wide,
      CameraLensType.zoom,
    });
  }

  @override
  Future<void> dispose() {
    // No-op.
    return Future.value();
  }
}
