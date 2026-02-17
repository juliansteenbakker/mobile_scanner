import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/objects/mobile_scanner_state.dart';

void main() {
  group('$MobileScannerState tests', () {
    group('constructor', () {
      test('creates instance with required values', () {
        const state = MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.normal,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.on,
          zoomScale: 1.5,
          deviceOrientation: DeviceOrientation.portraitUp,
        );

        expect(state.availableCameras, 2);
        expect(state.cameraDirection, CameraFacing.back);
        expect(state.cameraLensType, CameraLensType.normal);
        expect(state.isInitialized, true);
        expect(state.isStarting, false);
        expect(state.isRunning, true);
        expect(state.size, const Size(1920, 1080));
        expect(state.torchState, TorchState.on);
        expect(state.zoomScale, 1.5);
        expect(state.deviceOrientation, DeviceOrientation.portraitUp);
        expect(state.error, isNull);
      });

      test('creates instance with error', () {
        const error = MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        );

        const state = MobileScannerState(
          availableCameras: 0,
          cameraDirection: CameraFacing.unknown,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: false,
          size: Size.zero,
          torchState: TorchState.unavailable,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitUp,
          error: error,
        );

        expect(state.error, isNotNull);
        expect(state.error!.errorCode, MobileScannerErrorCode.permissionDenied);
      });
    });

    group('uninitialized', () {
      test('creates uninitialized state with default values', () {
        const state = MobileScannerState.uninitialized();

        expect(state.availableCameras, isNull);
        expect(state.cameraDirection, CameraFacing.unknown);
        expect(state.cameraLensType, CameraLensType.any);
        expect(state.isInitialized, false);
        expect(state.isStarting, false);
        expect(state.isRunning, false);
        expect(state.size, Size.zero);
        expect(state.torchState, TorchState.unavailable);
        expect(state.zoomScale, 1);
        expect(state.deviceOrientation, DeviceOrientation.portraitUp);
        expect(state.error, isNull);
      });
    });

    group('hasCameraPermission', () {
      test('returns true when initialized without permission error', () {
        const state = MobileScannerState(
          availableCameras: 1,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.normal,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.off,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitUp,
        );

        expect(state.hasCameraPermission, true);
      });

      test('returns false when not initialized', () {
        const state = MobileScannerState.uninitialized();

        expect(state.hasCameraPermission, false);
      });

      test('returns false when permission is denied', () {
        const state = MobileScannerState(
          availableCameras: 0,
          cameraDirection: CameraFacing.unknown,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: false,
          size: Size.zero,
          torchState: TorchState.unavailable,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitUp,
          error: MobileScannerException(
            errorCode: MobileScannerErrorCode.permissionDenied,
          ),
        );

        expect(state.hasCameraPermission, false);
      });

      test('returns true when error is not permission denied', () {
        const state = MobileScannerState(
          availableCameras: 1,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.normal,
          isInitialized: true,
          isStarting: false,
          isRunning: false,
          size: Size.zero,
          torchState: TorchState.unavailable,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitUp,
          error: MobileScannerException(
            errorCode: MobileScannerErrorCode.genericError,
          ),
        );

        expect(state.hasCameraPermission, true);
      });
    });

    group('copyWith', () {
      test('returns copy with no changes when no parameters provided', () {
        const original = MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.normal,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.on,
          zoomScale: 1.5,
          deviceOrientation: DeviceOrientation.portraitUp,
        );

        final copy = original.copyWith();

        expect(copy.availableCameras, original.availableCameras);
        expect(copy.cameraDirection, original.cameraDirection);
        expect(copy.cameraLensType, original.cameraLensType);
        expect(copy.isInitialized, original.isInitialized);
        expect(copy.isStarting, original.isStarting);
        expect(copy.isRunning, original.isRunning);
        expect(copy.size, original.size);
        expect(copy.torchState, original.torchState);
        expect(copy.zoomScale, original.zoomScale);
        expect(copy.deviceOrientation, original.deviceOrientation);
      });

      test('updates availableCameras', () {
        const original = MobileScannerState.uninitialized();

        final copy = original.copyWith(availableCameras: 3);

        expect(copy.availableCameras, 3);
      });

      test('updates cameraDirection', () {
        const original = MobileScannerState.uninitialized();

        final copy = original.copyWith(cameraDirection: CameraFacing.front);

        expect(copy.cameraDirection, CameraFacing.front);
      });

      test('updates cameraLensType', () {
        const original = MobileScannerState.uninitialized();

        final copy = original.copyWith(cameraLensType: CameraLensType.wide);

        expect(copy.cameraLensType, CameraLensType.wide);
      });

      test('updates isInitialized', () {
        const original = MobileScannerState.uninitialized();

        final copy = original.copyWith(isInitialized: true);

        expect(copy.isInitialized, true);
      });

      test('updates isStarting', () {
        const original = MobileScannerState.uninitialized();

        final copy = original.copyWith(isStarting: true);

        expect(copy.isStarting, true);
      });

      test('updates isRunning', () {
        const original = MobileScannerState.uninitialized();

        final copy = original.copyWith(isRunning: true);

        expect(copy.isRunning, true);
      });

      test('updates size', () {
        const original = MobileScannerState.uninitialized();

        final copy = original.copyWith(size: const Size(1280, 720));

        expect(copy.size, const Size(1280, 720));
      });

      test('updates torchState', () {
        const original = MobileScannerState.uninitialized();

        final copy = original.copyWith(torchState: TorchState.on);

        expect(copy.torchState, TorchState.on);
      });

      test('updates zoomScale', () {
        const original = MobileScannerState.uninitialized();

        final copy = original.copyWith(zoomScale: 2.5);

        expect(copy.zoomScale, 2.5);
      });

      test('updates deviceOrientation', () {
        const original = MobileScannerState.uninitialized();

        final copy = original.copyWith(
          deviceOrientation: DeviceOrientation.landscapeLeft,
        );

        expect(copy.deviceOrientation, DeviceOrientation.landscapeLeft);
      });

      test('updates error', () {
        const original = MobileScannerState.uninitialized();

        const error = MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        );

        final copy = original.copyWith(error: error);

        expect(copy.error, error);
      });

      test('clears error when null provided', () {
        const error = MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        );

        const original = MobileScannerState(
          availableCameras: 1,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.normal,
          isInitialized: true,
          isStarting: false,
          isRunning: false,
          size: Size.zero,
          torchState: TorchState.unavailable,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitUp,
          error: error,
        );

        final copy = original.copyWith();

        expect(copy.error, isNull);
      });

      test('updates multiple values at once', () {
        const original = MobileScannerState.uninitialized();

        final copy = original.copyWith(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          isInitialized: true,
          isRunning: true,
          size: const Size(1920, 1080),
          torchState: TorchState.off,
        );

        expect(copy.availableCameras, 2);
        expect(copy.cameraDirection, CameraFacing.back);
        expect(copy.isInitialized, true);
        expect(copy.isRunning, true);
        expect(copy.size, const Size(1920, 1080));
        expect(copy.torchState, TorchState.off);
        // Unchanged values
        expect(copy.cameraLensType, CameraLensType.any);
        expect(copy.isStarting, false);
        expect(copy.zoomScale, 1);
      });
    });
  });
}
