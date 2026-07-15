import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getBestQrScanningLens', () {
    tearDown(() {
      MobileScannerPlatform.instance = MethodChannelMobileScanner();
    });

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

    test('returns the lens reported by the platform', () async {
      MobileScannerPlatform.instance = FakeMobileScannerPlatform(
        CameraLensType.wide,
      );

      final controller = MobileScannerController(autoStart: false);

      final result = await controller.getBestQrScanningLens(
        // The back facing is the default; passed explicitly for readability.
        // ignore: avoid_redundant_argument_values
        facing: CameraFacing.back,
      );

      expect(result, CameraLensType.wide);
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

    test('returns null when the platform reports no camera', () async {
      MobileScannerPlatform.instance = FakeMobileScannerPlatform(null);

      final controller = MobileScannerController(autoStart: false);

      final result = await controller.getBestQrScanningLens();

      expect(result, isNull);
    });
  });
}

class FakeMobileScannerPlatform extends MobileScannerPlatform {
  FakeMobileScannerPlatform(CameraLensType? lensType) : _lensType = lensType;

  final CameraLensType? _lensType;

  @override
  Future<CameraLensType?> getBestQrScanningLens({
    CameraFacing facing = CameraFacing.back,
  }) {
    return Future.value(_lensType);
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
  Future<CameraLensType?> getBestQrScanningLens({
    CameraFacing facing = CameraFacing.back,
  }) {
    capturedFacing = facing;
    return Future.value(_lensType);
  }

  @override
  Future<void> dispose() {
    return Future.value();
  }
}
