import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/method_channel/android_surface_producer_delegate.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';

void main() {
  group('$AndroidSurfaceProducerDelegate tests', () {
    group('constructor', () {
      test('creates instance with all parameters', () {
        final delegate = AndroidSurfaceProducerDelegate(
          cameraFacingDirection: CameraFacing.back,
          handlesCropAndRotation: true,
          initialDeviceOrientation: DeviceOrientation.portraitUp,
          sensorOrientationDegrees: 90.0,
        );

        expect(delegate.cameraFacingDirection, CameraFacing.back);
        expect(delegate.handlesCropAndRotation, true);
        expect(delegate.initialDeviceOrientation, DeviceOrientation.portraitUp);
        expect(delegate.sensorOrientationDegrees, 90.0);
      });

      test('creates instance with front camera', () {
        final delegate = AndroidSurfaceProducerDelegate(
          cameraFacingDirection: CameraFacing.front,
          handlesCropAndRotation: false,
          initialDeviceOrientation: DeviceOrientation.landscapeLeft,
          sensorOrientationDegrees: 270.0,
        );

        expect(delegate.cameraFacingDirection, CameraFacing.front);
        expect(delegate.handlesCropAndRotation, false);
        expect(
          delegate.initialDeviceOrientation,
          DeviceOrientation.landscapeLeft,
        );
        expect(delegate.sensorOrientationDegrees, 270.0);
      });

      test('handles all DeviceOrientation values', () {
        for (final orientation in DeviceOrientation.values) {
          final delegate = AndroidSurfaceProducerDelegate(
            cameraFacingDirection: CameraFacing.back,
            handlesCropAndRotation: true,
            initialDeviceOrientation: orientation,
            sensorOrientationDegrees: 90.0,
          );

          expect(
            delegate.initialDeviceOrientation,
            orientation,
            reason: 'Should handle $orientation',
          );
        }
      });

      test('handles all CameraFacing values', () {
        for (final facing in CameraFacing.values) {
          final delegate = AndroidSurfaceProducerDelegate(
            cameraFacingDirection: facing,
            handlesCropAndRotation: true,
            initialDeviceOrientation: DeviceOrientation.portraitUp,
            sensorOrientationDegrees: 90.0,
          );

          expect(
            delegate.cameraFacingDirection,
            facing,
            reason: 'Should handle $facing',
          );
        }
      });

      test('handles various sensor orientation degrees', () {
        final testDegrees = [0.0, 90.0, 180.0, 270.0, 45.0, 135.0];

        for (final degrees in testDegrees) {
          final delegate = AndroidSurfaceProducerDelegate(
            cameraFacingDirection: CameraFacing.back,
            handlesCropAndRotation: true,
            initialDeviceOrientation: DeviceOrientation.portraitUp,
            sensorOrientationDegrees: degrees,
          );

          expect(
            delegate.sensorOrientationDegrees,
            degrees,
            reason: 'Should handle $degrees degrees',
          );
        }
      });
    });

    group('fromConfiguration factory', () {
      test('creates instance from valid configuration', () {
        final config = <String, Object?>{
          'handlesCropAndRotation': true,
          'naturalDeviceOrientation': 'PORTRAIT_UP',
          'sensorOrientation': 90,
        };

        final delegate = AndroidSurfaceProducerDelegate.fromConfiguration(
          config,
          CameraFacing.back,
        );

        expect(delegate.cameraFacingDirection, CameraFacing.back);
        expect(delegate.handlesCropAndRotation, true);
        expect(delegate.initialDeviceOrientation, DeviceOrientation.portraitUp);
        expect(delegate.sensorOrientationDegrees, 90.0);
      });

      test('creates instance with landscapeLeft orientation', () {
        final config = <String, Object?>{
          'handlesCropAndRotation': false,
          'naturalDeviceOrientation': 'LANDSCAPE_LEFT',
          'sensorOrientation': 0,
        };

        final delegate = AndroidSurfaceProducerDelegate.fromConfiguration(
          config,
          CameraFacing.front,
        );

        expect(delegate.cameraFacingDirection, CameraFacing.front);
        expect(delegate.handlesCropAndRotation, false);
        expect(
          delegate.initialDeviceOrientation,
          DeviceOrientation.landscapeLeft,
        );
        expect(delegate.sensorOrientationDegrees, 0.0);
      });

      test('creates instance with landscapeRight orientation', () {
        final config = <String, Object?>{
          'handlesCropAndRotation': true,
          'naturalDeviceOrientation': 'LANDSCAPE_RIGHT',
          'sensorOrientation': 180,
        };

        final delegate = AndroidSurfaceProducerDelegate.fromConfiguration(
          config,
          CameraFacing.back,
        );

        expect(
          delegate.initialDeviceOrientation,
          DeviceOrientation.landscapeRight,
        );
        expect(delegate.sensorOrientationDegrees, 180.0);
      });

      test('creates instance with portraitDown orientation', () {
        final config = <String, Object?>{
          'handlesCropAndRotation': true,
          'naturalDeviceOrientation': 'PORTRAIT_DOWN',
          'sensorOrientation': 270,
        };

        final delegate = AndroidSurfaceProducerDelegate.fromConfiguration(
          config,
          CameraFacing.back,
        );

        expect(
          delegate.initialDeviceOrientation,
          DeviceOrientation.portraitDown,
        );
        expect(delegate.sensorOrientationDegrees, 270.0);
      });

      test('throws MobileScannerException when handlesCropAndRotation is missing',
          () {
        final config = <String, Object?>{
          'naturalDeviceOrientation': 'PORTRAIT_UP',
          'sensorOrientation': 90,
        };

        expect(
          () => AndroidSurfaceProducerDelegate.fromConfiguration(
            config,
            CameraFacing.back,
          ),
          throwsA(
            isA<MobileScannerException>().having(
              (e) => e.errorCode,
              'errorCode',
              MobileScannerErrorCode.genericError,
            ),
          ),
        );
      });

      test(
          'throws MobileScannerException when naturalDeviceOrientation is missing',
          () {
        final config = <String, Object?>{
          'handlesCropAndRotation': true,
          'sensorOrientation': 90,
        };

        expect(
          () => AndroidSurfaceProducerDelegate.fromConfiguration(
            config,
            CameraFacing.back,
          ),
          throwsA(
            isA<MobileScannerException>().having(
              (e) => e.errorCode,
              'errorCode',
              MobileScannerErrorCode.genericError,
            ),
          ),
        );
      });

      test('throws MobileScannerException when sensorOrientation is missing',
          () {
        final config = <String, Object?>{
          'handlesCropAndRotation': true,
          'naturalDeviceOrientation': 'PORTRAIT_UP',
        };

        expect(
          () => AndroidSurfaceProducerDelegate.fromConfiguration(
            config,
            CameraFacing.back,
          ),
          throwsA(
            isA<MobileScannerException>().having(
              (e) => e.errorCode,
              'errorCode',
              MobileScannerErrorCode.genericError,
            ),
          ),
        );
      });

      test('throws MobileScannerException with empty config', () {
        final config = <String, Object?>{};

        expect(
          () => AndroidSurfaceProducerDelegate.fromConfiguration(
            config,
            CameraFacing.back,
          ),
          throwsA(
            isA<MobileScannerException>().having(
              (e) => e.errorDetails?.message,
              'errorDetails.message',
              'The start method did not return a valid configuration.',
            ),
          ),
        );
      });

      test(
          'throws MobileScannerException when handlesCropAndRotation has wrong type',
          () {
        final config = <String, Object?>{
          'handlesCropAndRotation': 'true', // String instead of bool
          'naturalDeviceOrientation': 'PORTRAIT_UP',
          'sensorOrientation': 90,
        };

        expect(
          () => AndroidSurfaceProducerDelegate.fromConfiguration(
            config,
            CameraFacing.back,
          ),
          throwsA(isA<MobileScannerException>()),
        );
      });

      test(
          'throws MobileScannerException when sensorOrientation has wrong type',
          () {
        final config = <String, Object?>{
          'handlesCropAndRotation': true,
          'naturalDeviceOrientation': 'PORTRAIT_UP',
          'sensorOrientation': '90', // String instead of int
        };

        expect(
          () => AndroidSurfaceProducerDelegate.fromConfiguration(
            config,
            CameraFacing.back,
          ),
          throwsA(isA<MobileScannerException>()),
        );
      });

      test('throws ArgumentError for invalid device orientation string', () {
        final config = <String, Object?>{
          'handlesCropAndRotation': true,
          'naturalDeviceOrientation': 'INVALID_ORIENTATION',
          'sensorOrientation': 90,
        };

        expect(
          () => AndroidSurfaceProducerDelegate.fromConfiguration(
            config,
            CameraFacing.back,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
