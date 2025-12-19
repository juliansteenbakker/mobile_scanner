import 'dart:async';

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

  setUpAll(() {
    registerFallbackValue(() {});
    registerFallbackValue(Rect.zero);
    registerFallbackValue(Offset.zero);
  });

  setUp(() {
    MobileScannerPlatform.instance = MockMethodChannelMobileScanner();
  });

  MobileScannerState createRunningState() {
    return const MobileScannerState(
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
    );
  }

  MockMobileScannerController createMockController({
    MobileScannerState? state,
    bool autoStart = true,
    Stream<BarcodeCapture>? barcodeStream,
  }) {
    final mockController = MockMobileScannerController();
    final streamController = StreamController<BarcodeCapture>.broadcast();

    when(() => mockController.autoStart).thenReturn(autoStart);
    when(
      () => mockController.barcodes,
    ).thenAnswer((_) => barcodeStream ?? streamController.stream);
    when(() => mockController.value).thenReturn(state ?? createRunningState());
    when(mockController.start).thenAnswer((_) async {});
    when(mockController.stop).thenAnswer((_) async {});
    when(mockController.dispose).thenAnswer((_) async {});
    when(mockController.attach).thenReturn(null);
    when(() => mockController.addListener(any())).thenReturn(null);
    when(() => mockController.removeListener(any())).thenReturn(null);
    when(() => mockController.updateScanWindow(any())).thenAnswer((_) async {});
    when(() => mockController.setFocusPoint(any())).thenAnswer((_) async {});

    return mockController;
  }

  group('MobileScanner Widget', () {
    testWidgets('shows placeholder when not initialized', (tester) async {
      final mockController = createMockController(
        state: const MobileScannerState.uninitialized(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: mockController),
          ),
        ),
      );

      final coloredBoxFinder = find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == Colors.black,
      );
      expect(coloredBoxFinder, findsOneWidget);
    });

    testWidgets('shows custom placeholder when provided', (tester) async {
      final mockController = createMockController(
        state: const MobileScannerState.uninitialized(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: mockController,
              placeholderBuilder: (context) => const Text('Loading...'),
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('shows default error widget on error', (tester) async {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );

      final mockController = createMockController(
        state: const MobileScannerState(
          availableCameras: 0,
          cameraDirection: CameraFacing.unknown,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: false,
          size: Size.zero,
          torchState: TorchState.unavailable,
          zoomScale: 1,
          error: exception,
          deviceOrientation: DeviceOrientation.portraitUp,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: mockController),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('shows custom error widget when provided', (tester) async {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );

      final mockController = createMockController(
        state: const MobileScannerState(
          availableCameras: 0,
          cameraDirection: CameraFacing.unknown,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: false,
          size: Size.zero,
          torchState: TorchState.unavailable,
          zoomScale: 1,
          error: exception,
          deviceOrientation: DeviceOrientation.portraitUp,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: mockController,
              errorBuilder: (context, error) {
                return Text('Error: ${error.errorCode}');
              },
            ),
          ),
        ),
      );

      expect(
        find.text('Error: MobileScannerErrorCode.permissionDenied'),
        findsOneWidget,
      );
    });

    testWidgets('calls onDetect when barcode is detected', (tester) async {
      BarcodeCapture? capturedBarcode;
      final streamController = StreamController<BarcodeCapture>.broadcast();

      final mockController = createMockController(
        barcodeStream: streamController.stream,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: mockController,
              onDetect: (capture) {
                capturedBarcode = capture;
              },
            ),
          ),
        ),
      );

      const expectedCapture = BarcodeCapture(
        barcodes: [Barcode(rawValue: '12345')],
      );
      streamController.add(expectedCapture);

      await tester.pump();

      expect(capturedBarcode, expectedCapture);

      await streamController.close();
    });

    testWidgets('shows overlay when overlayBuilder is provided', (
      tester,
    ) async {
      final mockController = createMockController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: mockController,
              overlayBuilder: (context, constraints) {
                return ColoredBox(
                  color: Colors.red.withAlpha(128),
                  child: const Center(child: Text('Overlay')),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Overlay'), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('uses BoxFit.cover by default', (tester) async {
      final mockController = createMockController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: mockController),
          ),
        ),
      );

      final fittedBox = tester.widget<FittedBox>(find.byType(FittedBox));
      expect(fittedBox.fit, BoxFit.cover);
    });

    testWidgets('uses custom BoxFit when provided', (tester) async {
      final mockController = createMockController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: mockController,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );

      final fittedBox = tester.widget<FittedBox>(find.byType(FittedBox));
      expect(fittedBox.fit, BoxFit.contain);
    });

    testWidgets('GestureDetector is present when tapToFocus is true', (
      tester,
    ) async {
      final mockController = createMockController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: mockController,
              tapToFocus: true,
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('no GestureDetector when tapToFocus is false', (tester) async {
      final mockController = createMockController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: mockController),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('calls attach on controller', (tester) async {
      final mockController = createMockController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: mockController),
          ),
        ),
      );

      verify(mockController.attach).called(1);
    });

    testWidgets('calls start when autoStart is true', (tester) async {
      final mockController = createMockController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: mockController),
          ),
        ),
      );

      await tester.pump();

      verify(mockController.start).called(1);
    });

    testWidgets('does not dispose externally provided controller', (
      tester,
    ) async {
      final mockController = createMockController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: mockController),
          ),
        ),
      );

      await tester.pumpWidget(Container());

      verifyNever(mockController.dispose);
    });

    testWidgets('updates scan window when scanWindow is provided', (
      tester,
    ) async {
      final mockController = createMockController();
      const scanWindow = Rect.fromLTWH(100, 100, 200, 200);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: mockController,
              scanWindow: scanWindow,
            ),
          ),
        ),
      );

      await tester.pump();

      verify(() => mockController.updateScanWindow(any())).called(1);
    });

    testWidgets('default values are correct', (tester) async {
      const widget = MobileScanner();

      expect(widget.controller, isNull);
      expect(widget.onDetect, isNull);
      expect(widget.fit, BoxFit.cover);
      expect(widget.errorBuilder, isNull);
      expect(widget.overlayBuilder, isNull);
      expect(widget.placeholderBuilder, isNull);
      expect(widget.scanWindow, isNull);
      expect(widget.scanWindowUpdateThreshold, 0.0);
      expect(widget.useAppLifecycleState, isTrue);
      expect(widget.tapToFocus, isFalse);
    });
  });

  group('MobileScanner different BoxFit values', () {
    for (final boxFit in BoxFit.values) {
      testWidgets('renders with BoxFit.$boxFit', (tester) async {
        final mockController = createMockController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileScanner(
                controller: mockController,
                fit: boxFit,
              ),
            ),
          ),
        );

        final fittedBox = tester.widget<FittedBox>(find.byType(FittedBox));
        expect(fittedBox.fit, boxFit);
      });
    }
  });

  group('MobileScanner error states', () {
    for (final errorCode in MobileScannerErrorCode.values) {
      testWidgets('handles ${errorCode.name} error', (tester) async {
        final exception = MobileScannerException(errorCode: errorCode);

        final mockController = createMockController(
          state: MobileScannerState(
            availableCameras: 0,
            cameraDirection: CameraFacing.unknown,
            cameraLensType: CameraLensType.any,
            isInitialized: true,
            isStarting: false,
            isRunning: false,
            size: Size.zero,
            torchState: TorchState.unavailable,
            zoomScale: 1,
            error: exception,
            deviceOrientation: DeviceOrientation.portraitUp,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileScanner(controller: mockController),
            ),
          ),
        );

        expect(find.byIcon(Icons.error), findsOneWidget);
      });
    }
  });

  group('MobileScanner controller states', () {
    testWidgets('handles front camera', (tester) async {
      final mockController = createMockController(
        state: const MobileScannerState(
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
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: mockController),
          ),
        ),
      );

      expect(find.byType(FittedBox), findsOneWidget);
    });

    testWidgets('handles landscape orientation', (tester) async {
      final mockController = createMockController(
        state: const MobileScannerState(
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
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: mockController),
          ),
        ),
      );

      expect(find.byType(FittedBox), findsOneWidget);
    });

    testWidgets('handles different lens types', (tester) async {
      for (final lensType in CameraLensType.values) {
        final mockController = createMockController(
          state: MobileScannerState(
            availableCameras: 2,
            cameraDirection: CameraFacing.back,
            cameraLensType: lensType,
            isInitialized: true,
            isStarting: false,
            isRunning: true,
            size: const Size(1920, 1080),
            torchState: TorchState.off,
            zoomScale: 1,
            deviceOrientation: DeviceOrientation.portraitUp,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileScanner(controller: mockController),
            ),
          ),
        );

        expect(find.byType(FittedBox), findsOneWidget);
      }
    });

    testWidgets('handles torch on state', (tester) async {
      final mockController = createMockController(
        state: const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: Size(1920, 1080),
          torchState: TorchState.on,
          zoomScale: 1,
          deviceOrientation: DeviceOrientation.portraitUp,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: mockController),
          ),
        ),
      );

      expect(find.byType(FittedBox), findsOneWidget);
    });

    testWidgets('handles different zoom scales', (tester) async {
      for (final zoomScale in [0.0, 0.5, 1.0]) {
        final mockController = createMockController(
          state: MobileScannerState(
            availableCameras: 2,
            cameraDirection: CameraFacing.back,
            cameraLensType: CameraLensType.any,
            isInitialized: true,
            isStarting: false,
            isRunning: true,
            size: const Size(1920, 1080),
            torchState: TorchState.off,
            zoomScale: zoomScale,
            deviceOrientation: DeviceOrientation.portraitUp,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileScanner(controller: mockController),
            ),
          ),
        );

        expect(find.byType(FittedBox), findsOneWidget);
      }
    });
  });
}
