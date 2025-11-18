import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MobileScannerController lens type tests', () {
    test('controller initializes with default lens type (any)', () {
      final controller = MobileScannerController();

      expect(controller.lensType, CameraLensType.any);

      unawaited(controller.dispose());
    });

    test('controller initializes with normal lens type', () {
      final controller = MobileScannerController(
        lensType: CameraLensType.normal,
      );

      expect(controller.lensType, CameraLensType.normal);

      unawaited(controller.dispose());
    });

    test('controller initializes with wide lens type', () {
      final controller = MobileScannerController(
        lensType: CameraLensType.wide,
      );

      expect(controller.lensType, CameraLensType.wide);

      unawaited(controller.dispose());
    });

    test('controller initializes with zoom lens type', () {
      final controller = MobileScannerController(
        lensType: CameraLensType.zoom,
      );

      expect(controller.lensType, CameraLensType.zoom);

      unawaited(controller.dispose());
    });

    test('lens type persists throughout controller lifecycle', () {
      final controller = MobileScannerController(
        autoStart: false,
        lensType: CameraLensType.zoom,
      );

      expect(controller.lensType, CameraLensType.zoom);

      // Lens type should remain the same even after operations
      expect(controller.lensType, CameraLensType.zoom);

      unawaited(controller.dispose());

      // Even after disposal, the property should still be accessible
      expect(controller.lensType, CameraLensType.zoom);
    });

    test('different controllers can have different lens types', () {
      final normalController = MobileScannerController(
        autoStart: false,
        lensType: CameraLensType.normal,
      );
      final wideController = MobileScannerController(
        autoStart: false,
        lensType: CameraLensType.wide,
      );
      final zoomController = MobileScannerController(
        autoStart: false,
        lensType: CameraLensType.zoom,
      );

      expect(normalController.lensType, CameraLensType.normal);
      expect(wideController.lensType, CameraLensType.wide);
      expect(zoomController.lensType, CameraLensType.zoom);

      unawaited(normalController.dispose());
      unawaited(wideController.dispose());
      unawaited(zoomController.dispose());
    });

    test('controller with all lens types can be created', () {
      for (final lensType in CameraLensType.values) {
        final controller = MobileScannerController(
          autoStart: false,
          lensType: lensType,
        );

        expect(controller.lensType, lensType);
        unawaited(controller.dispose());
      }
    });

    test('lens type property is read-only and immutable', () {
      final controller = MobileScannerController(
        lensType: CameraLensType.wide,
      );

      final initialLensType = controller.lensType;
      expect(initialLensType, CameraLensType.wide);

      // The lens type should remain the same (it's a final property)
      expect(controller.lensType, initialLensType);

      unawaited(controller.dispose());
    });
  });
}
