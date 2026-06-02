import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getBestQrScanningLens', () {
    test('throws when controller is disposed', () async {
      MobileScannerPlatform.instance = FakeMobileScannerPlatform(
        CameraLensType.normal,
      );

      final controller = MobileScannerController(autoStart: false);

      await controller.dispose();

      expect(
        controller.getBestQrScanningLens,
        throwsA(
          isA<MobileScannerException>().having(
            (e) => e.errorCode,
            'errorCode',
            MobileScannerErrorCode.controllerDisposed,
          ),
        ),
      );
    });

    test('returns best lens from platform', () async {
      MobileScannerPlatform.instance = FakeMobileScannerPlatform(
        CameraLensType.wide,
      );

      final controller = MobileScannerController(autoStart: false);

      final result = await controller.getBestQrScanningLens();

      expect(result, CameraLensType.wide);
    });

    test('returns normal lens as default from platform', () async {
      MobileScannerPlatform.instance = FakeMobileScannerPlatform(
        CameraLensType.normal,
      );

      final controller = MobileScannerController(autoStart: false);

      final result = await controller.getBestQrScanningLens();

      expect(result, CameraLensType.normal);
    });

    test('passes facing parameter to platform', () async {
      final fake = FakeMobileScannerPlatformWithFacingCapture(
        CameraLensType.normal,
      );
      MobileScannerPlatform.instance = fake;

      final controller = MobileScannerController(autoStart: false);

      await controller.getBestQrScanningLens(facing: CameraFacing.front);

      expect(fake.capturedFacing, CameraFacing.front);
    });
  });
}

class FakeMobileScannerPlatform extends MobileScannerPlatform {
  FakeMobileScannerPlatform(CameraLensType lensType) : _lensType = lensType;

  final CameraLensType _lensType;

  @override
  Future<CameraLensType> getBestQrScanningLens({
    CameraFacing facing = CameraFacing.back,
  }) {
    return Future.value(_lensType);
  }

  @override
  Future<Set<CameraLensType>> getSupportedLenses() {
    return Future.value(<CameraLensType>{});
  }

  @override
  Future<void> dispose() {
    return Future.value();
  }
}

class FakeMobileScannerPlatformWithFacingCapture extends MobileScannerPlatform {
  FakeMobileScannerPlatformWithFacingCapture(CameraLensType lensType)
    : _lensType = lensType;

  final CameraLensType _lensType;
  CameraFacing? capturedFacing;

  @override
  Future<CameraLensType> getBestQrScanningLens({
    CameraFacing facing = CameraFacing.back,
  }) {
    capturedFacing = facing;
    return Future.value(_lensType);
  }

  @override
  Future<Set<CameraLensType>> getSupportedLenses() {
    return Future.value(<CameraLensType>{});
  }

  @override
  Future<void> dispose() {
    return Future.value();
  }
}
