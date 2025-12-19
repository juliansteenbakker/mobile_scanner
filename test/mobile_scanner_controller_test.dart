import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMobileScannerPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements MethodChannelMobileScanner {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMobileScannerPlatform mockPlatform;
  late StreamController<BarcodeCapture?> barcodesStreamController;
  late StreamController<TorchState> torchStateStreamController;
  late StreamController<double> zoomScaleStreamController;
  late StreamController<DeviceOrientation> deviceOrientationStreamController;

  setUpAll(() {
    registerFallbackValue(
      const StartOptions(
        cameraDirection: CameraFacing.back,
        cameraLensType: CameraLensType.any,
        cameraResolution: null,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 250,
        formats: <BarcodeFormat>[],
        returnImage: false,
        torchEnabled: false,
        invertImage: false,
        autoZoom: false,
        initialZoom: null,
      ),
    );
    registerFallbackValue(Offset.zero);
    registerFallbackValue(Rect.zero);
    registerFallbackValue(<BarcodeFormat>[]);
  });

  setUp(() {
    mockPlatform = MockMobileScannerPlatform();
    barcodesStreamController = StreamController<BarcodeCapture?>.broadcast();
    torchStateStreamController = StreamController<TorchState>.broadcast();
    zoomScaleStreamController = StreamController<double>.broadcast();
    deviceOrientationStreamController =
        StreamController<DeviceOrientation>.broadcast();

    when(() => mockPlatform.barcodesStream)
        .thenAnswer((_) => barcodesStreamController.stream);
    when(() => mockPlatform.torchStateStream)
        .thenAnswer((_) => torchStateStreamController.stream);
    when(() => mockPlatform.zoomScaleStateStream)
        .thenAnswer((_) => zoomScaleStreamController.stream);
    when(() => mockPlatform.deviceOrientationChangedStream)
        .thenAnswer((_) => deviceOrientationStreamController.stream);
    when(() => mockPlatform.dispose()).thenAnswer((_) async {});
    when(() => mockPlatform.stop()).thenAnswer((_) async {});
    when(() => mockPlatform.pause()).thenAnswer((_) async {});

    MobileScannerPlatform.instance = mockPlatform;
  });

  tearDown(() {
    unawaited(barcodesStreamController.close());
    unawaited(torchStateStreamController.close());
    unawaited(zoomScaleStreamController.close());
    unawaited(deviceOrientationStreamController.close());
  });

  group('MobileScannerController constructor', () {
    test('creates with default values', () {
      final controller = MobileScannerController(autoStart: false);

      expect(controller.autoStart, isFalse);
      expect(controller.cameraResolution, isNull);
      expect(controller.lensType, CameraLensType.any);
      expect(controller.detectionSpeed, DetectionSpeed.normal);
      expect(controller.detectionTimeoutMs, 250);
      expect(controller.facing, CameraFacing.back);
      expect(controller.formats, isEmpty);
      expect(controller.returnImage, isFalse);
      expect(controller.torchEnabled, isFalse);
      expect(controller.invertImage, isFalse);
      expect(controller.autoZoom, isFalse);
      expect(controller.initialZoom, isNull);
      expect(controller.value, const MobileScannerState.uninitialized());
    });

    test('creates with custom values', () {
      final controller = MobileScannerController(
        autoStart: false,
        cameraResolution: const Size(1280, 720),
        lensType: CameraLensType.wide,
        detectionSpeed: DetectionSpeed.noDuplicates,
        detectionTimeoutMs: 500,
        facing: CameraFacing.front,
        formats: const [BarcodeFormat.qrCode, BarcodeFormat.ean13],
        returnImage: true,
        torchEnabled: true,
        invertImage: true,
        autoZoom: true,
        initialZoom: 0.5,
      );

      expect(controller.cameraResolution, const Size(1280, 720));
      expect(controller.lensType, CameraLensType.wide);
      expect(controller.detectionSpeed, DetectionSpeed.noDuplicates);
      expect(controller.detectionTimeoutMs, 0);
      expect(controller.facing, CameraFacing.front);
      expect(controller.formats.length, 2);
      expect(controller.returnImage, isTrue);
      expect(controller.torchEnabled, isTrue);
      expect(controller.invertImage, isTrue);
      expect(controller.autoZoom, isTrue);
      expect(controller.initialZoom, 0.5);
    });

    test('sets detectionTimeoutMs to 0 for noDuplicates speed', () {
      final controller = MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.noDuplicates,
        detectionTimeoutMs: 500,
      );

      expect(controller.detectionTimeoutMs, 0);
    });

    test('sets detectionTimeoutMs to 0 for unrestricted speed', () {
      final controller = MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.unrestricted,
        detectionTimeoutMs: 500,
      );

      expect(controller.detectionTimeoutMs, 0);
    });

    test('preserves detectionTimeoutMs for normal speed', () {
      final controller = MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 500,
      );

      expect(controller.detectionTimeoutMs, 500);
    });

    test('throws assertion error for negative detectionTimeoutMs', () {
      expect(
        () => MobileScannerController(
          autoStart: false,
          detectionTimeoutMs: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws assertion error for CameraFacing.unknown', () {
      expect(
        () => MobileScannerController(
          autoStart: false,
          facing: CameraFacing.unknown,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('MobileScannerController.barcodes', () {
    test('returns barcodes stream', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();

      final barcode = const BarcodeCapture(
        barcodes: [Barcode(rawValue: 'test')],
      );

      barcodesStreamController.add(barcode);

      await expectLater(
        controller.barcodes,
        emits(barcode),
      );

      await controller.dispose();
    });

    test('forwards errors from platform barcodes stream', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();

      final error = Exception('Test error');
      barcodesStreamController.addError(error);

      await expectLater(
        controller.barcodes,
        emitsError(error),
      );

      await controller.dispose();
    });
  });

  group('MobileScannerController.buildCameraView', () {
    test('throws when not initialized', () {
      final controller = MobileScannerController(autoStart: false);

      expect(
        () => controller.buildCameraView(),
        throwsA(
          isA<MobileScannerException>().having(
            (e) => e.errorCode,
            'errorCode',
            MobileScannerErrorCode.controllerUninitialized,
          ),
        ),
      );
    });

    test('throws when disposed', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();
      await controller.dispose();

      expect(
        () => controller.buildCameraView(),
        throwsA(
          isA<MobileScannerException>().having(
            (e) => e.errorCode,
            'errorCode',
            MobileScannerErrorCode.controllerDisposed,
          ),
        ),
      );
    });
  });

  group('MobileScannerController.resetZoomScale', () {
    test('throws when not initialized', () {
      final controller = MobileScannerController(autoStart: false);

      expect(
        controller.resetZoomScale,
        throwsA(
          isA<MobileScannerException>().having(
            (e) => e.errorCode,
            'errorCode',
            MobileScannerErrorCode.controllerUninitialized,
          ),
        ),
      );
    });

    test('does nothing when not running', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();
      await controller.stop();

      await controller.resetZoomScale();

      verifyNever(() => mockPlatform.resetZoomScale());

      await controller.dispose();
    });

    test('calls platform resetZoomScale when running', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );
      when(() => mockPlatform.resetZoomScale()).thenAnswer((_) async {});

      await controller.start();
      await controller.resetZoomScale();

      verify(() => mockPlatform.resetZoomScale()).called(1);

      await controller.dispose();
    });
  });

  group('MobileScannerController.setZoomScale', () {
    test('throws when not initialized', () {
      final controller = MobileScannerController(autoStart: false);

      expect(
        () => controller.setZoomScale(0.5),
        throwsA(
          isA<MobileScannerException>().having(
            (e) => e.errorCode,
            'errorCode',
            MobileScannerErrorCode.controllerUninitialized,
          ),
        ),
      );
    });

    test('does nothing when not running', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();
      await controller.stop();

      await controller.setZoomScale(0.5);

      verifyNever(() => mockPlatform.setZoomScale(any()));

      await controller.dispose();
    });

    test('clamps zoom scale to 0.0-1.0 range', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );
      when(() => mockPlatform.setZoomScale(any())).thenAnswer((_) async {});

      await controller.start();

      await controller.setZoomScale(-0.5);
      verify(() => mockPlatform.setZoomScale(0.0)).called(1);

      await controller.setZoomScale(1.5);
      verify(() => mockPlatform.setZoomScale(1.0)).called(1);

      await controller.setZoomScale(0.5);
      verify(() => mockPlatform.setZoomScale(0.5)).called(1);

      await controller.dispose();
    });
  });

  group('MobileScannerController.setFocusPoint', () {
    test('throws when not initialized', () {
      final controller = MobileScannerController(autoStart: false);

      expect(
        () => controller.setFocusPoint(const Offset(0.5, 0.5)),
        throwsA(
          isA<MobileScannerException>().having(
            (e) => e.errorCode,
            'errorCode',
            MobileScannerErrorCode.controllerUninitialized,
          ),
        ),
      );
    });

    test('does nothing when not running', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();
      await controller.stop();

      await controller.setFocusPoint(const Offset(0.5, 0.5));

      verifyNever(() => mockPlatform.setFocusPoint(any()));

      await controller.dispose();
    });

    test('clamps focus point to 0.0-1.0 range', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );
      when(() => mockPlatform.setFocusPoint(any())).thenAnswer((_) async {});

      await controller.start();

      await controller.setFocusPoint(const Offset(-0.5, 1.5));
      verify(() => mockPlatform.setFocusPoint(const Offset(0.0, 1.0))).called(1);

      await controller.setFocusPoint(const Offset(0.5, 0.5));
      verify(() => mockPlatform.setFocusPoint(const Offset(0.5, 0.5))).called(1);

      await controller.dispose();
    });
  });

  group('MobileScannerController.start', () {
    test('throws when disposed before attach', () async {
      final controller = MobileScannerController(autoStart: false);

      await controller.dispose();

      expect(
        controller.start,
        throwsA(
          isA<MobileScannerException>().having(
            (e) => e.errorCode,
            'errorCode',
            MobileScannerErrorCode.controllerDisposed,
          ),
        ),
      );
    });

    test('throws when CameraFacing.unknown is passed', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      expect(
        () => controller.start(cameraDirection: CameraFacing.unknown),
        throwsA(
          isA<MobileScannerException>().having(
            (e) => e.errorCode,
            'errorCode',
            MobileScannerErrorCode.genericError,
          ),
        ),
      );

      await controller.dispose();
    });

    test('does nothing when already running', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();
      await controller.start();

      verify(() => mockPlatform.start(any())).called(1);

      await controller.dispose();
    });

    test('handles platform error gracefully', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenThrow(
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
      );

      await controller.start();

      expect(controller.value.error, isNotNull);
      expect(
        controller.value.error!.errorCode,
        MobileScannerErrorCode.permissionDenied,
      );
      expect(controller.value.isRunning, isFalse);
      expect(controller.value.isInitialized, isTrue);

      await controller.dispose();
    });

    test('uses custom camera direction and lens type', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.front,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start(
        cameraDirection: CameraFacing.front,
        cameraLensType: CameraLensType.wide,
      );

      final captured = verify(() => mockPlatform.start(captureAny())).captured;
      final options = captured.first as StartOptions;

      expect(options.cameraDirection, CameraFacing.front);
      expect(options.cameraLensType, CameraLensType.wide);

      await controller.dispose();
    });

    test('updates state on successful start', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.on,
          numberOfCameras: 3,
          initialDeviceOrientation: DeviceOrientation.landscapeLeft,
        ),
      );

      await controller.start();

      expect(controller.value.isInitialized, isTrue);
      expect(controller.value.isRunning, isTrue);
      expect(controller.value.cameraDirection, CameraFacing.back);
      expect(controller.value.size, const Size(1920, 1080));
      expect(controller.value.torchState, TorchState.on);
      expect(controller.value.availableCameras, 3);
      expect(
        controller.value.deviceOrientation,
        DeviceOrientation.landscapeLeft,
      );

      await controller.dispose();
    });
  });

  group('MobileScannerController.stop', () {
    test('does nothing when not initialized', () async {
      final controller = MobileScannerController(autoStart: false);

      await controller.stop();

      verifyNever(() => mockPlatform.stop());
    });

    test('does nothing when already stopped', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();
      await controller.stop();
      await controller.stop();

      verify(() => mockPlatform.stop()).called(1);

      await controller.dispose();
    });

    test('sets torch state to off when stopping', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.on,
        ),
      );

      await controller.start();
      expect(controller.value.torchState, TorchState.on);

      await controller.stop();
      expect(controller.value.torchState, TorchState.off);
      expect(controller.value.isRunning, isFalse);

      await controller.dispose();
    });

    test('preserves unavailable torch state when stopping', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.unavailable,
        ),
      );

      await controller.start();
      expect(controller.value.torchState, TorchState.unavailable);

      await controller.stop();
      expect(controller.value.torchState, TorchState.unavailable);

      await controller.dispose();
    });
  });

  group('MobileScannerController.pause', () {
    test('calls platform pause when running', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();
      await controller.pause();

      verify(() => mockPlatform.pause()).called(1);
      expect(controller.value.isRunning, isFalse);

      await controller.dispose();
    });

    test('does nothing when not running', () async {
      final controller = MobileScannerController(autoStart: false);

      await controller.pause();

      verifyNever(() => mockPlatform.pause());
    });
  });

  group('MobileScannerController.toggleTorch', () {
    test('throws when not initialized', () {
      final controller = MobileScannerController(autoStart: false);

      expect(
        controller.toggleTorch,
        throwsA(
          isA<MobileScannerException>().having(
            (e) => e.errorCode,
            'errorCode',
            MobileScannerErrorCode.controllerUninitialized,
          ),
        ),
      );
    });

    test('does nothing when not running', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();
      await controller.stop();

      await controller.toggleTorch();

      verifyNever(() => mockPlatform.toggleTorch());

      await controller.dispose();
    });

    test('does nothing when torch is unavailable', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.unavailable,
        ),
      );

      await controller.start();
      await controller.toggleTorch();

      verifyNever(() => mockPlatform.toggleTorch());

      await controller.dispose();
    });

    test('calls platform toggleTorch when available and running', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );
      when(() => mockPlatform.toggleTorch()).thenAnswer((_) async {});

      await controller.start();
      await controller.toggleTorch();

      verify(() => mockPlatform.toggleTorch()).called(1);

      await controller.dispose();
    });
  });

  group('MobileScannerController.updateScanWindow', () {
    test('does nothing when disposed', () async {
      final controller = MobileScannerController(autoStart: false);

      await controller.dispose();

      await controller.updateScanWindow(
        const Rect.fromLTWH(0, 0, 100, 100),
      );

      verifyNever(() => mockPlatform.updateScanWindow(any()));
    });

    test('does nothing when not initialized', () async {
      final controller = MobileScannerController(autoStart: false);

      await controller.updateScanWindow(
        const Rect.fromLTWH(0, 0, 100, 100),
      );

      verifyNever(() => mockPlatform.updateScanWindow(any()));

      await controller.dispose();
    });

    test('calls platform updateScanWindow when initialized', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );
      when(() => mockPlatform.updateScanWindow(any())).thenAnswer((_) async {});

      await controller.start();

      const scanWindow = Rect.fromLTWH(10, 20, 200, 300);
      await controller.updateScanWindow(scanWindow);

      verify(() => mockPlatform.updateScanWindow(scanWindow)).called(1);

      await controller.dispose();
    });

    test('can pass null to reset scan window', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );
      when(() => mockPlatform.updateScanWindow(any())).thenAnswer((_) async {});

      await controller.start();

      await controller.updateScanWindow(null);

      verify(() => mockPlatform.updateScanWindow(null)).called(1);

      await controller.dispose();
    });
  });

  group('MobileScannerController.dispose', () {
    test('does nothing when already disposed', () async {
      final controller = MobileScannerController(autoStart: false);

      await controller.dispose();
      await controller.dispose();

      verify(() => mockPlatform.dispose()).called(1);
    });

    test('closes barcode stream', () async {
      final controller = MobileScannerController(autoStart: false);

      var streamClosed = false;
      final subscription = controller.barcodes.listen(
        (_) {},
        onDone: () => streamClosed = true,
      );

      await controller.dispose();

      // Give time for the stream to close
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(streamClosed, isTrue);

      await subscription.cancel();
    });
  });

  group('MobileScannerController.attach', () {
    test('can only be called once', () {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();
      controller.attach();

      expect(true, isTrue);
    });
  });

  group('MobileScannerController stream listeners', () {
    test('updates torch state from stream', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();

      torchStateStreamController.add(TorchState.on);

      await Future<void>.delayed(Duration.zero);

      expect(controller.value.torchState, TorchState.on);

      await controller.dispose();
    });

    test('updates zoom scale from stream', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();

      zoomScaleStreamController.add(0.75);

      await Future<void>.delayed(Duration.zero);

      expect(controller.value.zoomScale, 0.75);

      await controller.dispose();
    });

    test('ignores stream updates after dispose', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();
      await controller.dispose();

      torchStateStreamController.add(TorchState.on);
      zoomScaleStreamController.add(0.5);

      await Future<void>.delayed(Duration.zero);
    });

    test('ignores null barcode captures', () async {
      final controller = MobileScannerController(autoStart: false);

      controller.attach();

      when(() => mockPlatform.start(any())).thenAnswer(
        (_) async => const MobileScannerViewAttributes(
          cameraDirection: CameraFacing.back,
          size: Size(1920, 1080),
          currentTorchMode: TorchState.off,
        ),
      );

      await controller.start();

      var barcodeReceived = false;
      final subscription = controller.barcodes.listen((_) {
        barcodeReceived = true;
      });

      barcodesStreamController.add(null);

      await Future<void>.delayed(Duration.zero);

      expect(barcodeReceived, isFalse);

      await subscription.cancel();
      await controller.dispose();
    });
  });

  group('MobileScannerController.analyzeImage', () {
    test('calls platform analyzeImage', () async {
      final controller = MobileScannerController(autoStart: false);

      when(
        () => mockPlatform.analyzeImage(any(), formats: any(named: 'formats')),
      ).thenAnswer(
        (_) async => const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'test')],
        ),
      );

      final result = await controller.analyzeImage('/path/to/image.png');

      expect(result, isNotNull);
      expect(result!.barcodes.first.rawValue, 'test');

      verify(
        () => mockPlatform.analyzeImage(
          '/path/to/image.png',
          formats: any(named: 'formats'),
        ),
      ).called(1);

      await controller.dispose();
    });

    test('analyzeImage with custom formats', () async {
      final controller = MobileScannerController(autoStart: false);

      when(
        () => mockPlatform.analyzeImage(any(), formats: any(named: 'formats')),
      ).thenAnswer((_) async => null);

      await controller.analyzeImage(
        '/path/to/image.png',
        formats: [BarcodeFormat.qrCode],
      );

      verify(
        () => mockPlatform.analyzeImage(
          '/path/to/image.png',
          formats: [BarcodeFormat.qrCode],
        ),
      ).called(1);

      await controller.dispose();
    });
  });
}
