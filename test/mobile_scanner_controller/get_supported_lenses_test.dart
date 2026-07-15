import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getSupportedLenses', () {
    test('throws when controller is disposed', () async {
      MobileScannerPlatform.instance = FakeMobileScannerPlatform(const {
        CameraLensType.any,
      });

      final controller = MobileScannerController(autoStart: false);

      await controller.dispose();

      expect(
        controller.getSupportedLenses,
        throwsA(
          isA<MobileScannerException>().having(
            (e) => e.errorCode,
            'errorCode',
            MobileScannerErrorCode.controllerDisposed,
          ),
        ),
      );
    });

    test('returns supported lenses', () async {
      MobileScannerPlatform.instance = FakeMobileScannerPlatform(const {
        CameraLensType.wide,
        CameraLensType.normal,
      });

      final controller = MobileScannerController(autoStart: false);

      final supportedLense = await controller.getSupportedLenses();

      expect(supportedLense, {CameraLensType.wide, CameraLensType.normal});
    });

    test('passes facing parameter to platform', () async {
      final fake = FakeMobileScannerPlatformWithFacingCapture(const {
        CameraLensType.normal,
      });
      MobileScannerPlatform.instance = fake;

      final controller = MobileScannerController(autoStart: false);

      await controller.getSupportedLenses(facing: CameraFacing.front);

      expect(fake.capturedFacing, CameraFacing.front);
    });
  });
}

class FakeMobileScannerPlatform extends MobileScannerPlatform {
  FakeMobileScannerPlatform(Set<CameraLensType> supportedLenses)
    : _supportedLenses = supportedLenses;

  final Set<CameraLensType> _supportedLenses;

  @override
  Future<Set<CameraLensType>> getSupportedLenses({CameraFacing? facing}) {
    return Future.value(_supportedLenses);
  }

  @override
  Future<void> dispose() {
    // No-op.
    return Future.value();
  }
}

class FakeMobileScannerPlatformWithFacingCapture extends MobileScannerPlatform {
  FakeMobileScannerPlatformWithFacingCapture(
    Set<CameraLensType> supportedLenses,
  ) : _supportedLenses = supportedLenses;

  final Set<CameraLensType> _supportedLenses;
  CameraFacing? capturedFacing;

  @override
  Future<Set<CameraLensType>> getSupportedLenses({CameraFacing? facing}) {
    capturedFacing = facing;
    return Future.value(_supportedLenses);
  }

  @override
  Future<void> dispose() {
    // No-op.
    return Future.value();
  }
}
