import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';

void main() {
  group('$StartOptions tests', () {
    test('toMap includes all required fields', () {
      const options = StartOptions(
        cameraDirection: CameraFacing.back,
        cameraLensType: CameraLensType.normal,
        cameraResolution: null,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 250,
        formats: [],
        returnImage: false,
        torchEnabled: false,
        invertImage: false,
        autoZoom: false,
        initialZoom: null,
      );

      final map = options.toMap();

      expect(map['facing'], CameraFacing.back.rawValue);
      expect(map['lensType'], CameraLensType.normal.rawValue);
      expect(map['speed'], DetectionSpeed.normal.rawValue);
      expect(map['timeout'], 250);
      expect(map['returnImage'], false);
      expect(map['torch'], false);
      expect(map['invertImage'], false);
      expect(map['autoZoom'], false);
    });

    test('toMap includes camera resolution when provided', () {
      const options = StartOptions(
        cameraDirection: CameraFacing.back,
        cameraLensType: CameraLensType.any,
        cameraResolution: Size(1920, 1080),
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 250,
        formats: [],
        returnImage: false,
        torchEnabled: false,
        invertImage: false,
        autoZoom: false,
        initialZoom: null,
      );

      final map = options.toMap();

      expect(map['cameraResolution'], [1920, 1080]);
    });

    test('toMap excludes camera resolution when null', () {
      const options = StartOptions(
        cameraDirection: CameraFacing.back,
        cameraLensType: CameraLensType.any,
        cameraResolution: null,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 250,
        formats: [],
        returnImage: false,
        torchEnabled: false,
        invertImage: false,
        autoZoom: false,
        initialZoom: null,
      );

      final map = options.toMap();

      expect(map.containsKey('cameraResolution'), false);
    });

    test('toMap includes formats when provided', () {
      const options = StartOptions(
        cameraDirection: CameraFacing.back,
        cameraLensType: CameraLensType.any,
        cameraResolution: null,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 250,
        formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
        returnImage: false,
        torchEnabled: false,
        invertImage: false,
        autoZoom: false,
        initialZoom: null,
      );

      final map = options.toMap();

      expect(
        map['formats'],
        [BarcodeFormat.qrCode.rawValue, BarcodeFormat.code128.rawValue],
      );
    });

    test('toMap excludes formats when empty', () {
      const options = StartOptions(
        cameraDirection: CameraFacing.back,
        cameraLensType: CameraLensType.any,
        cameraResolution: null,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 250,
        formats: [],
        returnImage: false,
        torchEnabled: false,
        invertImage: false,
        autoZoom: false,
        initialZoom: null,
      );

      final map = options.toMap();

      expect(map.containsKey('formats'), false);
    });

    test('toMap correctly maps all lens types', () {
      const lensTypes = [
        CameraLensType.normal,
        CameraLensType.wide,
        CameraLensType.zoom,
        CameraLensType.any,
      ];

      for (final lensType in lensTypes) {
        final options = StartOptions(
          cameraDirection: CameraFacing.back,
          cameraLensType: lensType,
          cameraResolution: null,
          detectionSpeed: DetectionSpeed.normal,
          detectionTimeoutMs: 250,
          formats: [],
          returnImage: false,
          torchEnabled: false,
          invertImage: false,
          autoZoom: false,
          initialZoom: null,
        );

        final map = options.toMap();

        expect(
          map['lensType'],
          lensType.rawValue,
          reason:
              'Lens type $lensType should map to raw value '
              '${lensType.rawValue}',
        );
      }
    });

    test('toMap includes initialZoom when provided', () {
      const options = StartOptions(
        cameraDirection: CameraFacing.back,
        cameraLensType: CameraLensType.any,
        cameraResolution: null,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 250,
        formats: [],
        returnImage: false,
        torchEnabled: false,
        invertImage: false,
        autoZoom: false,
        initialZoom: 2,
      );

      final map = options.toMap();

      expect(map['initialZoom'], 2);
    });

    test('toMap handles all camera facing directions', () {
      const facingDirections = [
        CameraFacing.front,
        CameraFacing.back,
        CameraFacing.external,
      ];

      for (final facing in facingDirections) {
        final options = StartOptions(
          cameraDirection: facing,
          cameraLensType: CameraLensType.any,
          cameraResolution: null,
          detectionSpeed: DetectionSpeed.normal,
          detectionTimeoutMs: 250,
          formats: [],
          returnImage: false,
          torchEnabled: false,
          invertImage: false,
          autoZoom: false,
          initialZoom: null,
        );

        final map = options.toMap();

        expect(
          map['facing'],
          facing.rawValue,
          reason:
              'Camera facing $facing should map to raw value '
              '${facing.rawValue}',
        );
      }
    });

    test('toMap handles boolean flags correctly', () {
      const testCases = [
        (returnImage: true, torch: true, invertImage: true, autoZoom: true),
        (returnImage: false, torch: false, invertImage: false, autoZoom: false),
        (returnImage: true, torch: false, invertImage: true, autoZoom: false),
      ];

      for (final testCase in testCases) {
        final options = StartOptions(
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          cameraResolution: null,
          detectionSpeed: DetectionSpeed.normal,
          detectionTimeoutMs: 250,
          formats: [],
          returnImage: testCase.returnImage,
          torchEnabled: testCase.torch,
          invertImage: testCase.invertImage,
          autoZoom: testCase.autoZoom,
          initialZoom: null,
        );

        final map = options.toMap();

        expect(map['returnImage'], testCase.returnImage);
        expect(map['torch'], testCase.torch);
        expect(map['invertImage'], testCase.invertImage);
        expect(map['autoZoom'], testCase.autoZoom);
      }
    });
  });
}
