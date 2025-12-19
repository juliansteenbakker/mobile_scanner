import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';

void main() {
  group('$MobileScannerViewAttributes tests', () {
    test('can be constructed with required parameters only', () {
      const attributes = MobileScannerViewAttributes(
        cameraDirection: CameraFacing.back,
        currentTorchMode: TorchState.off,
        size: Size(1920, 1080),
      );

      expect(attributes.cameraDirection, CameraFacing.back);
      expect(attributes.currentTorchMode, TorchState.off);
      expect(attributes.size, const Size(1920, 1080));
      expect(attributes.numberOfCameras, isNull);
      expect(attributes.initialDeviceOrientation, isNull);
    });

    test('can be constructed with all parameters', () {
      const attributes = MobileScannerViewAttributes(
        cameraDirection: CameraFacing.front,
        currentTorchMode: TorchState.on,
        size: Size(1280, 720),
        numberOfCameras: 3,
        initialDeviceOrientation: DeviceOrientation.portraitUp,
      );

      expect(attributes.cameraDirection, CameraFacing.front);
      expect(attributes.currentTorchMode, TorchState.on);
      expect(attributes.size, const Size(1280, 720));
      expect(attributes.numberOfCameras, 3);
      expect(attributes.initialDeviceOrientation, DeviceOrientation.portraitUp);
    });

    test('handles all CameraFacing values', () {
      for (final facing in CameraFacing.values) {
        final attributes = MobileScannerViewAttributes(
          cameraDirection: facing,
          currentTorchMode: TorchState.off,
          size: const Size(1920, 1080),
        );

        expect(
          attributes.cameraDirection,
          facing,
          reason: 'CameraFacing.$facing should be stored correctly',
        );
      }
    });

    test('handles all TorchState values', () {
      for (final torchState in TorchState.values) {
        final attributes = MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          currentTorchMode: torchState,
          size: const Size(1920, 1080),
        );

        expect(
          attributes.currentTorchMode,
          torchState,
          reason: 'TorchState.$torchState should be stored correctly',
        );
      }
    });

    test('handles all DeviceOrientation values', () {
      for (final orientation in DeviceOrientation.values) {
        final attributes = MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          currentTorchMode: TorchState.off,
          size: const Size(1920, 1080),
          initialDeviceOrientation: orientation,
        );

        expect(
          attributes.initialDeviceOrientation,
          orientation,
          reason: 'DeviceOrientation.$orientation should be stored correctly',
        );
      }
    });

    test('stores various size values correctly', () {
      const testSizes = [
        Size(640, 480),
        Size(1280, 720),
        Size(1920, 1080),
        Size(3840, 2160),
        Size(0, 0),
      ];

      for (final size in testSizes) {
        final attributes = MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          currentTorchMode: TorchState.off,
          size: size,
        );

        expect(
          attributes.size,
          size,
          reason: 'Size $size should be stored correctly',
        );
      }
    });

    test('stores various numberOfCameras values correctly', () {
      const testValues = [0, 1, 2, 3, 5, 10];

      for (final count in testValues) {
        final attributes = MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          currentTorchMode: TorchState.off,
          size: const Size(1920, 1080),
          numberOfCameras: count,
        );

        expect(
          attributes.numberOfCameras,
          count,
          reason: 'numberOfCameras $count should be stored correctly',
        );
      }
    });

    test('can be used as const', () {
      const attributes = MobileScannerViewAttributes(
        cameraDirection: CameraFacing.back,
        currentTorchMode: TorchState.off,
        size: Size(1920, 1080),
        numberOfCameras: 2,
        initialDeviceOrientation: DeviceOrientation.landscapeLeft,
      );

      expect(attributes, isA<MobileScannerViewAttributes>());
    });

    test('handles front camera with torch unavailable', () {
      const attributes = MobileScannerViewAttributes(
        cameraDirection: CameraFacing.front,
        currentTorchMode: TorchState.unavailable,
        size: Size(1920, 1080),
      );

      expect(attributes.cameraDirection, CameraFacing.front);
      expect(attributes.currentTorchMode, TorchState.unavailable);
    });

    test('handles torch auto mode', () {
      const attributes = MobileScannerViewAttributes(
        cameraDirection: CameraFacing.back,
        currentTorchMode: TorchState.auto,
        size: Size(1920, 1080),
      );

      expect(attributes.currentTorchMode, TorchState.auto);
    });
  });
}
