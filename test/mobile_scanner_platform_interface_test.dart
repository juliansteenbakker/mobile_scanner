import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMobileScannerPlatform extends MobileScannerPlatform
    with MockPlatformInterfaceMixin {
  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) async {
    return null;
  }

  @override
  Widget buildCameraView() => const SizedBox();

  @override
  Future<void> resetZoomScale() async {}

  @override
  Future<void> setZoomScale(double zoomScale) async {}

  @override
  Future<void> setFocusPoint(Offset position) async {}

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(1920, 1080),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> toggleTorch() async {}

  @override
  Future<Set<CameraLensType>> getSupportedLenses() async {
    return {CameraLensType.any};
  }

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> dispose() async {}
}

class SubclassMobileScannerPlatform extends MobileScannerPlatform {
  SubclassMobileScannerPlatform() : super();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MobileScannerPlatform originalPlatform;

  setUp(() {
    originalPlatform = MobileScannerPlatform.instance;
  });

  tearDown(() {
    MobileScannerPlatform.instance = originalPlatform;
  });

  group('$MobileScannerPlatform tests', () {
    test('default instance is MethodChannelMobileScanner', () {
      expect(
        MobileScannerPlatform.instance,
        isNotNull,
      );
    });

    test('can set and get instance with valid platform implementation', () {
      final mockPlatform = MockMobileScannerPlatform();

      MobileScannerPlatform.instance = mockPlatform;

      expect(MobileScannerPlatform.instance, mockPlatform);
    });

    test('allows setting subclass that extends MobileScannerPlatform', () {
      // Subclasses that properly extend MobileScannerPlatform inherit the token
      // through the super constructor, so they are valid implementations.
      final subclass = SubclassMobileScannerPlatform();

      MobileScannerPlatform.instance = subclass;

      expect(MobileScannerPlatform.instance, subclass);
    });

    group('unimplemented methods throw UnimplementedError', () {
      late MobileScannerPlatform basePlatform;

      setUp(() {
        basePlatform = MockMobileScannerPlatformBase();
      });

      test('barcodesStream throws UnimplementedError', () {
        expect(
          () => basePlatform.barcodesStream,
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'barcodesStream has not been implemented.',
            ),
          ),
        );
      });

      test('torchStateStream throws UnimplementedError', () {
        expect(
          () => basePlatform.torchStateStream,
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'torchStateStream has not been implemented.',
            ),
          ),
        );
      });

      test('zoomScaleStateStream throws UnimplementedError', () {
        expect(
          () => basePlatform.zoomScaleStateStream,
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'zoomScaleStateStream has not been implemented.',
            ),
          ),
        );
      });

      test('analyzeImage throws UnimplementedError', () {
        expect(
          () => basePlatform.analyzeImage('/path/to/image.png'),
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'analyzeImage() has not been implemented.',
            ),
          ),
        );
      });

      test('buildCameraView throws UnimplementedError', () {
        expect(
          () => basePlatform.buildCameraView(),
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'buildCameraView() has not been implemented.',
            ),
          ),
        );
      });

      test('resetZoomScale throws UnimplementedError', () {
        expect(
          () => basePlatform.resetZoomScale(),
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'resetZoomScale() has not been implemented.',
            ),
          ),
        );
      });

      test('setZoomScale throws UnimplementedError', () {
        expect(
          () => basePlatform.setZoomScale(0.5),
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'setZoomScale() has not been implemented.',
            ),
          ),
        );
      });

      test('setFocusPoint throws UnimplementedError', () {
        expect(
          () => basePlatform.setFocusPoint(const Offset(0.5, 0.5)),
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'setFocusPoint() has not been implemented.',
            ),
          ),
        );
      });

      test('start throws UnimplementedError', () {
        const startOptions = StartOptions(
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

        expect(
          () => basePlatform.start(startOptions),
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'start() has not been implemented.',
            ),
          ),
        );
      });

      test('stop throws UnimplementedError', () {
        expect(
          () => basePlatform.stop(),
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'stop() has not been implemented.',
            ),
          ),
        );
      });

      test('pause throws UnimplementedError', () {
        expect(
          () => basePlatform.pause(),
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'pause() has not been implemented.',
            ),
          ),
        );
      });

      test('toggleTorch throws UnimplementedError', () {
        expect(
          () => basePlatform.toggleTorch(),
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'toggleTorch() has not been implemented.',
            ),
          ),
        );
      });

      test('getSupportedLenses throws UnimplementedError', () {
        expect(
          () => basePlatform.getSupportedLenses(),
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'getSupportedLenses() has not been implemented.',
            ),
          ),
        );
      });

      test('updateScanWindow throws UnimplementedError', () {
        expect(
          () => basePlatform.updateScanWindow(const Rect.fromLTWH(0, 0, 100, 100)),
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'updateScanWindow() has not been implemented.',
            ),
          ),
        );
      });

      test('dispose throws UnimplementedError', () {
        expect(
          () => basePlatform.dispose(),
          throwsA(
            isA<UnimplementedError>().having(
              (e) => e.message,
              'message',
              'dispose() has not been implemented.',
            ),
          ),
        );
      });

      test('setBarcodeLibraryScriptUrl does not throw (empty implementation)',
          () {
        expect(
          () => basePlatform.setBarcodeLibraryScriptUrl('https://example.com/barcode.js'),
          returnsNormally,
        );
      });
    });

    group('mock platform implementation works correctly', () {
      late MockMobileScannerPlatform mockPlatform;

      setUp(() {
        mockPlatform = MockMobileScannerPlatform();
        MobileScannerPlatform.instance = mockPlatform;
      });

      test('barcodesStream returns stream', () {
        expect(mockPlatform.barcodesStream, isA<Stream<BarcodeCapture?>>());
      });

      test('torchStateStream returns stream', () {
        expect(mockPlatform.torchStateStream, isA<Stream<TorchState>>());
      });

      test('zoomScaleStateStream returns stream', () {
        expect(mockPlatform.zoomScaleStateStream, isA<Stream<double>>());
      });

      test('analyzeImage returns null', () async {
        final result = await mockPlatform.analyzeImage('/path/to/image.png');
        expect(result, isNull);
      });

      test('analyzeImage accepts formats parameter', () async {
        final result = await mockPlatform.analyzeImage(
          '/path/to/image.png',
          formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
        );
        expect(result, isNull);
      });

      test('buildCameraView returns widget', () {
        final widget = mockPlatform.buildCameraView();
        expect(widget, isA<Widget>());
      });

      test('resetZoomScale completes', () async {
        await expectLater(mockPlatform.resetZoomScale(), completes);
      });

      test('setZoomScale completes', () async {
        await expectLater(mockPlatform.setZoomScale(0.5), completes);
      });

      test('setFocusPoint completes', () async {
        await expectLater(
          mockPlatform.setFocusPoint(const Offset(0.5, 0.5)),
          completes,
        );
      });

      test('start returns MobileScannerViewAttributes', () async {
        const startOptions = StartOptions(
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

        final result = await mockPlatform.start(startOptions);
        expect(result, isA<MobileScannerViewAttributes>());
        expect(result.cameraDirection, CameraFacing.back);
        expect(result.currentTorchMode, TorchState.off);
        expect(result.size, const Size(1920, 1080));
      });

      test('stop completes', () async {
        await expectLater(mockPlatform.stop(), completes);
      });

      test('pause completes', () async {
        await expectLater(mockPlatform.pause(), completes);
      });

      test('toggleTorch completes', () async {
        await expectLater(mockPlatform.toggleTorch(), completes);
      });

      test('getSupportedLenses returns set with any', () async {
        final result = await mockPlatform.getSupportedLenses();
        expect(result, {CameraLensType.any});
      });

      test('updateScanWindow completes with rect', () async {
        await expectLater(
          mockPlatform.updateScanWindow(const Rect.fromLTWH(0, 0, 100, 100)),
          completes,
        );
      });

      test('updateScanWindow completes with null', () async {
        await expectLater(mockPlatform.updateScanWindow(null), completes);
      });

      test('dispose completes', () async {
        await expectLater(mockPlatform.dispose(), completes);
      });
    });
  });
}

/// A base platform class that doesn't override any methods,
/// used to test the default UnimplementedError behavior.
class MockMobileScannerPlatformBase extends MobileScannerPlatform
    with MockPlatformInterfaceMixin {}
