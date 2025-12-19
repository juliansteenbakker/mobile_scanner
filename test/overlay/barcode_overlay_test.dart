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

  late MockMobileScannerController mockController;
  late StreamController<BarcodeCapture> barcodeStreamController;

  setUpAll(() {
    registerFallbackValue(() {});
  });

  setUp(() {
    MobileScannerPlatform.instance = MockMethodChannelMobileScanner();
    mockController = MockMobileScannerController();
    barcodeStreamController = StreamController<BarcodeCapture>.broadcast();

    when(() => mockController.addListener(any())).thenReturn(null);
    when(() => mockController.removeListener(any())).thenReturn(null);
    when(() => mockController.barcodes).thenAnswer(
      (_) => barcodeStreamController.stream,
    );
  });

  tearDown(() {
    unawaited(barcodeStreamController.close());
  });

  Finder findStackInOverlay() {
    return find.descendant(
      of: find.byType(BarcodeOverlay),
      matching: find.byType(Stack),
    );
  }

  Finder findCustomPaintInOverlay() {
    return find.descendant(
      of: find.byType(BarcodeOverlay),
      matching: find.byType(CustomPaint),
    );
  }

  group('BarcodeOverlay', () {
    testWidgets('renders empty SizedBox when controller is not initialized', (
      tester,
    ) async {
      when(() => mockController.value).thenReturn(
        const MobileScannerState.uninitialized(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BarcodeOverlay(
            boxFit: BoxFit.contain,
            controller: mockController,
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(SizedBox), findsWidgets);
      expect(findStackInOverlay(), findsNothing);
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
          home: BarcodeOverlay(
            boxFit: BoxFit.contain,
            controller: mockController,
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(SizedBox), findsWidgets);
      expect(findStackInOverlay(), findsNothing);
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
          home: BarcodeOverlay(
            boxFit: BoxFit.contain,
            controller: mockController,
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(SizedBox), findsWidgets);
      expect(findStackInOverlay(), findsNothing);
    });

    testWidgets('renders empty SizedBox when no barcode is captured', (
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
          home: BarcodeOverlay(
            boxFit: BoxFit.contain,
            controller: mockController,
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(SizedBox), findsWidgets);
      expect(findStackInOverlay(), findsNothing);
    });

    testWidgets('renders empty SizedBox when barcodeCapture size is empty', (
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
          home: BarcodeOverlay(
            boxFit: BoxFit.contain,
            controller: mockController,
          ),
        ),
      );

      barcodeStreamController.add(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'test')],
        ),
      );

      await tester.pump();

      expect(findStackInOverlay(), findsNothing);
    });

    testWidgets(
      'renders empty SizedBox when barcodeCapture barcodes is empty',
      (tester) async {
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
            home: BarcodeOverlay(
              boxFit: BoxFit.contain,
              controller: mockController,
            ),
          ),
        );

        barcodeStreamController.add(
          const BarcodeCapture(size: Size(1920, 1080)),
        );

        await tester.pump();

        expect(findStackInOverlay(), findsNothing);
      },
    );

    testWidgets('renders Stack with CustomPaint when barcode is captured', (
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
          home: BarcodeOverlay(
            boxFit: BoxFit.contain,
            controller: mockController,
          ),
        ),
      );

      barcodeStreamController.add(
        const BarcodeCapture(
          barcodes: [
            Barcode(
              rawValue: '123456',
              size: Size(100, 50),
              corners: [
                Offset(10, 10),
                Offset(110, 10),
                Offset(110, 60),
                Offset(10, 60),
              ],
            ),
          ],
          size: Size(1920, 1080),
        ),
      );

      await tester.pump();

      expect(findStackInOverlay(), findsOneWidget);
      expect(findCustomPaintInOverlay(), findsOneWidget);
    });

    testWidgets(
      'renders multiple CustomPaint widgets for multiple barcodes',
      (tester) async {
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
            home: BarcodeOverlay(
              boxFit: BoxFit.contain,
              controller: mockController,
            ),
          ),
        );

        barcodeStreamController.add(
          const BarcodeCapture(
            barcodes: [
              Barcode(
                rawValue: '111111',
                size: Size(100, 50),
                corners: [
                  Offset(10, 10),
                  Offset(110, 10),
                  Offset(110, 60),
                  Offset(10, 60),
                ],
              ),
              Barcode(
                rawValue: '222222',
                size: Size(100, 50),
                corners: [
                  Offset(200, 200),
                  Offset(300, 200),
                  Offset(300, 250),
                  Offset(200, 250),
                ],
              ),
            ],
            size: Size(1920, 1080),
          ),
        );

        await tester.pump();

        expect(findStackInOverlay(), findsOneWidget);
        expect(findCustomPaintInOverlay(), findsNWidgets(2));
      },
    );

    testWidgets(
      'skips barcodes with empty size or no corners',
      (tester) async {
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
            home: BarcodeOverlay(
              boxFit: BoxFit.contain,
              controller: mockController,
            ),
          ),
        );

        barcodeStreamController.add(
          const BarcodeCapture(
            barcodes: [
              Barcode(rawValue: 'no size', corners: [Offset(10, 10)]),
              Barcode(rawValue: 'no corners', size: Size(100, 50)),
              Barcode(
                rawValue: 'valid',
                size: Size(100, 50),
                corners: [
                  Offset(10, 10),
                  Offset(110, 10),
                  Offset(110, 60),
                  Offset(10, 60),
                ],
              ),
            ],
            size: Size(1920, 1080),
          ),
        );

        await tester.pump();

        expect(findStackInOverlay(), findsOneWidget);
        expect(findCustomPaintInOverlay(), findsOneWidget);
      },
    );

    testWidgets('uses default values correctly', (tester) async {
      when(() => mockController.value).thenReturn(
        const MobileScannerState.uninitialized(),
      );

      final overlay = BarcodeOverlay(
        boxFit: BoxFit.contain,
        controller: mockController,
      );

      expect(overlay.color, const Color(0x4DF44336));
      expect(overlay.style, PaintingStyle.fill);
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
          home: BarcodeOverlay(
            boxFit: BoxFit.cover,
            controller: mockController,
            color: Colors.blue.withValues(alpha: 0.5),
            style: PaintingStyle.stroke,
          ),
        ),
      );

      barcodeStreamController.add(
        const BarcodeCapture(
          barcodes: [
            Barcode(
              rawValue: '123456',
              size: Size(100, 50),
              corners: [
                Offset(10, 10),
                Offset(110, 10),
                Offset(110, 60),
                Offset(10, 60),
              ],
            ),
          ],
          size: Size(1920, 1080),
        ),
      );

      await tester.pump();

      expect(findStackInOverlay(), findsOneWidget);
      expect(findCustomPaintInOverlay(), findsOneWidget);
    });

    testWidgets('disposes TextPainter correctly', (tester) async {
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
          home: BarcodeOverlay(
            boxFit: BoxFit.contain,
            controller: mockController,
          ),
        ),
      );

      await tester.pumpWidget(Container());

      expect(tester.takeException(), isNull);
    });
  });
}
