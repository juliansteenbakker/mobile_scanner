import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/mobile_scanner_preview.dart';
import 'package:mocktail/mocktail.dart';

const _cameraViewKey = Key('camera_view_placeholder');

class MockMobileScannerController extends Mock
    implements MobileScannerController {
  MobileScannerState _state;

  MockMobileScannerController(this._state);

  @override
  MobileScannerState get value => _state;

  set state(MobileScannerState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  Widget buildCameraView() {
    return const Placeholder(key: _cameraViewKey);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$CameraPreview tests', () {
    testWidgets('shows empty SizedBox when controller is not initialized', (
      tester,
    ) async {
      final controller = MockMobileScannerController(
        const MobileScannerState.uninitialized(),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CameraPreview(controller))),
      );

      // Find the SizedBox that is a direct child (not one inside the preview)
      final sizedBoxFinder = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox &&
            widget.width == null &&
            widget.height == null &&
            widget.child == null,
      );

      expect(sizedBoxFinder, findsOneWidget);
    });

    testWidgets('shows camera view when controller is initialized in portrait',
        (tester) async {
      final controller = MockMobileScannerController(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.off,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitUp,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CameraPreview(controller))),
      );

      // Should find the camera view (Placeholder with key)
      expect(find.byKey(_cameraViewKey), findsOneWidget);

      // In portrait, size should not be flipped
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byKey(_cameraViewKey),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 1920);
      expect(sizedBox.height, 1080);
    });

    testWidgets(
        'shows camera view with flipped size when in landscape left orientation',
        (tester) async {
      final controller = MockMobileScannerController(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.off,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.landscapeLeft,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CameraPreview(controller))),
      );

      // Should find the camera view (Placeholder with key)
      expect(find.byKey(_cameraViewKey), findsOneWidget);

      // In landscape, size should be flipped (width and height swapped)
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byKey(_cameraViewKey),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 1080);
      expect(sizedBox.height, 1920);
    });

    testWidgets(
        'shows camera view with flipped size when in landscape right orientation',
        (tester) async {
      final controller = MockMobileScannerController(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.off,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.landscapeRight,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CameraPreview(controller))),
      );

      // In landscape, size should be flipped
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byKey(_cameraViewKey),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 1080);
      expect(sizedBox.height, 1920);
    });

    testWidgets('does not flip size for portraitDown orientation', (
      tester,
    ) async {
      final controller = MockMobileScannerController(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.off,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitDown,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CameraPreview(controller))),
      );

      // In portrait (even upside down), size should not be flipped
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byKey(_cameraViewKey),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 1920);
      expect(sizedBox.height, 1080);
    });

    testWidgets('wraps in RotatedBox on Android', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final controller = MockMobileScannerController(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.off,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.landscapeRight,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CameraPreview(controller))),
      );

      // On Android, should have a RotatedBox
      expect(find.byType(RotatedBox), findsOneWidget);

      // Verify quarter turns for landscapeRight (should be 1)
      final rotatedBox = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(rotatedBox.quarterTurns, 1);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('does not wrap in RotatedBox on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final controller = MockMobileScannerController(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.off,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitUp,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CameraPreview(controller))),
      );

      // On iOS, should NOT have a RotatedBox
      expect(find.byType(RotatedBox), findsNothing);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('does not wrap in RotatedBox on macOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      final controller = MockMobileScannerController(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.off,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitUp,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CameraPreview(controller))),
      );

      // On macOS, should NOT have a RotatedBox
      expect(find.byType(RotatedBox), findsNothing);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('RotatedBox has correct quarter turns for portraitUp', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final controller = MockMobileScannerController(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.off,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitUp,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CameraPreview(controller))),
      );

      final rotatedBox = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(rotatedBox.quarterTurns, 0);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('RotatedBox has correct quarter turns for portraitDown', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final controller = MockMobileScannerController(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.off,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitDown,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CameraPreview(controller))),
      );

      final rotatedBox = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(rotatedBox.quarterTurns, 2);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('RotatedBox has correct quarter turns for landscapeLeft', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final controller = MockMobileScannerController(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.off,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.landscapeLeft,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CameraPreview(controller))),
      );

      final rotatedBox = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(rotatedBox.quarterTurns, 3);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('handles various camera sizes', (tester) async {
      final testSizes = [
        const Size(640, 480),
        const Size(1280, 720),
        const Size(1920, 1080),
        const Size(3840, 2160),
      ];

      for (final size in testSizes) {
        final controller = MockMobileScannerController(
          MobileScannerState(
            availableCameras: 2,
            cameraDirection: CameraFacing.back,
            cameraLensType: CameraLensType.any,
            isInitialized: true,
            isStarting: false,
            isRunning: true,
            size: size,
            torchState: TorchState.off,
            zoomScale: 1,
            deviceOrientation: DeviceOrientation.portraitUp,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: CameraPreview(controller))),
        );

        final sizedBox = tester.widget<SizedBox>(
          find.ancestor(
            of: find.byKey(_cameraViewKey),
            matching: find.byType(SizedBox),
          ),
        );
        expect(
          sizedBox.width,
          size.width,
          reason: 'Width should match for size $size',
        );
        expect(
          sizedBox.height,
          size.height,
          reason: 'Height should match for size $size',
        );
      }
    });

    testWidgets('can be used as const', (tester) async {
      final controller = MockMobileScannerController(
        const MobileScannerState.uninitialized(),
      );

      // Verify that CameraPreview can be constructed with const
      final preview = CameraPreview(controller);

      expect(preview, isA<CameraPreview>());
      expect(preview.controller, controller);
    });

    testWidgets('handles front camera', (tester) async {
      final controller = MockMobileScannerController(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.front,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.unavailable,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitUp,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CameraPreview(controller))),
      );

      expect(find.byKey(_cameraViewKey), findsOneWidget);
    });
  });
}
