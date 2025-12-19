import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mocktail/mocktail.dart';

class MockMobileScannerController extends Mock
    implements MobileScannerController {
  @override
  Widget buildCameraView() {
    return const Placeholder(
      fallbackHeight: 100,
      fallbackWidth: 100,
      color: Color(0xFF00FF00),
    );
  }
}

class MockMethodChannelMobileScanner extends MethodChannelMobileScanner {
  @override
  Future<void> stop({bool force = false}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMobileScannerController mockController;

  setUpAll(() {
    registerFallbackValue(() {});
  });

  setUp(() {
    MobileScannerPlatform.instance = MockMethodChannelMobileScanner();
    mockController = MockMobileScannerController();

    when(() => mockController.addListener(any())).thenReturn(null);
    when(() => mockController.removeListener(any())).thenReturn(null);
  });

  Finder findCustomPaintInOverlay() {
    return find.descendant(
      of: find.byType(ScanWindowOverlay),
      matching: find.byType(CustomPaint),
    );
  }

  group('ScanWindowOverlay', () {
    testWidgets('renders empty SizedBox when scanWindow is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScanWindowOverlay(
            controller: mockController,
            scanWindow: Rect.zero,
          ),
        ),
      );

      expect(findCustomPaintInOverlay(), findsNothing);
    });

    testWidgets('renders empty SizedBox when scanWindow is infinite', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScanWindowOverlay(
            controller: mockController,
            scanWindow: const Rect.fromLTWH(
              0,
              0,
              double.infinity,
              double.infinity,
            ),
          ),
        ),
      );

      expect(findCustomPaintInOverlay(), findsNothing);
    });

    testWidgets('renders empty SizedBox when controller is not initialized', (
      tester,
    ) async {
      when(() => mockController.value).thenReturn(
        const MobileScannerState.uninitialized(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ScanWindowOverlay(
            controller: mockController,
            scanWindow: const Rect.fromLTWH(50, 100, 300, 300),
          ),
        ),
      );

      await tester.pump();

      expect(findCustomPaintInOverlay(), findsNothing);
    });

    testWidgets('renders empty SizedBox when controller is not running', (
      tester,
    ) async {
      when(() => mockController.value).thenReturn(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: false,
          size: Size(1920, 1080),
          torchState: TorchState.off,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitUp,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ScanWindowOverlay(
            controller: mockController,
            scanWindow: const Rect.fromLTWH(50, 100, 300, 300),
          ),
        ),
      );

      await tester.pump();

      expect(findCustomPaintInOverlay(), findsNothing);
    });

    testWidgets('renders empty SizedBox when controller has an error', (
      tester,
    ) async {
      when(() => mockController.value).thenReturn(
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
          error: MobileScannerException(
            errorCode: MobileScannerErrorCode.controllerUninitialized,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ScanWindowOverlay(
            controller: mockController,
            scanWindow: const Rect.fromLTWH(50, 100, 300, 300),
          ),
        ),
      );

      await tester.pump();

      expect(findCustomPaintInOverlay(), findsNothing);
    });

    testWidgets('renders empty SizedBox when controller size is empty', (
      tester,
    ) async {
      when(() => mockController.value).thenReturn(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size.zero,
          torchState: TorchState.off,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitUp,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ScanWindowOverlay(
            controller: mockController,
            scanWindow: const Rect.fromLTWH(50, 100, 300, 300),
          ),
        ),
      );

      await tester.pump();

      expect(findCustomPaintInOverlay(), findsNothing);
    });

    testWidgets('renders CustomPaint when controller is ready', (
      tester,
    ) async {
      when(() => mockController.value).thenReturn(
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
        MaterialApp(
          home: ScanWindowOverlay(
            controller: mockController,
            scanWindow: const Rect.fromLTWH(50, 100, 300, 300),
          ),
        ),
      );

      await tester.pump();

      expect(findCustomPaintInOverlay(), findsOneWidget);
    });

    testWidgets('uses default values correctly', (tester) async {
      when(() => mockController.value).thenReturn(
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

      final overlay = ScanWindowOverlay(
        controller: mockController,
        scanWindow: const Rect.fromLTWH(50, 100, 300, 300),
      );

      expect(overlay.borderColor, Colors.white);
      expect(overlay.borderRadius, BorderRadius.zero);
      expect(overlay.borderStrokeCap, StrokeCap.butt);
      expect(overlay.borderStrokeJoin, StrokeJoin.miter);
      expect(overlay.borderStyle, PaintingStyle.stroke);
      expect(overlay.borderWidth, 2.0);
      expect(overlay.color, const Color(0x80000000));
    });

    testWidgets('accepts custom styling parameters', (tester) async {
      when(() => mockController.value).thenReturn(
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
        MaterialApp(
          home: ScanWindowOverlay(
            controller: mockController,
            scanWindow: const Rect.fromLTWH(50, 100, 300, 300),
            borderColor: Colors.blue,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            borderStrokeCap: StrokeCap.round,
            borderStrokeJoin: StrokeJoin.round,
            borderStyle: PaintingStyle.fill,
            borderWidth: 4,
            color: const Color(0x60FF0000),
          ),
        ),
      );

      await tester.pump();

      expect(findCustomPaintInOverlay(), findsOneWidget);
    });
  });
}
