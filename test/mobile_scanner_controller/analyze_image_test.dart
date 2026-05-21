import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeMobileScannerPlatform fakePlatform;

  setUp(() {
    fakePlatform = _FakeMobileScannerPlatform();
    MobileScannerPlatform.instance = fakePlatform;
  });

  test('empty allowedLengths returns the platform result unchanged', () async {
    final controller = MobileScannerController(autoStart: false);
    addTearDown(controller.dispose);

    const platformResult = BarcodeCapture(
      barcodes: [
        Barcode(rawValue: '12345'),
        Barcode(rawValue: '12345678901234'),
      ],
    );
    fakePlatform.nextAnalyzeImageResult = platformResult;

    final result = await controller.analyzeImage('ignored.png');

    expect(identical(result, platformResult), isTrue);
  });

  test('applies allowedLengths to the platform result', () async {
    final controller = MobileScannerController(
      autoStart: false,
      allowedLengths: const {14},
    );
    addTearDown(controller.dispose);

    fakePlatform.nextAnalyzeImageResult = const BarcodeCapture(
      barcodes: [
        Barcode(rawValue: '12345'),
        Barcode(rawValue: '12345678901234'),
      ],
    );

    final result = await controller.analyzeImage('ignored.png');

    expect(result, isNotNull);
    expect(result!.barcodes.map((b) => b.rawValue).toList(), const [
      '12345678901234',
    ]);
  });

  test(
    'returns null when every barcode is dropped by allowedLengths',
    () async {
      final controller = MobileScannerController(
        autoStart: false,
        allowedLengths: const {14},
      );
      addTearDown(controller.dispose);

      fakePlatform.nextAnalyzeImageResult = const BarcodeCapture(
        barcodes: [Barcode(rawValue: '12345')],
      );

      final result = await controller.analyzeImage('ignored.png');

      expect(result, isNull);
    },
  );
}

class _FakeMobileScannerPlatform extends MobileScannerPlatform {
  BarcodeCapture? nextAnalyzeImageResult;

  @override
  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) async {
    return nextAnalyzeImageResult;
  }

  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream =>
      Stream.value(TorchState.unavailable);

  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) {
    return Future.value(
      const MobileScannerViewAttributes(
        cameraDirection: CameraFacing.back,
        currentTorchMode: TorchState.unavailable,
        size: Size(200, 200),
        numberOfCameras: 1,
      ),
    );
  }

  @override
  Widget buildCameraView() {
    return const SizedBox.square(dimension: 100);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> dispose() async {}
}
