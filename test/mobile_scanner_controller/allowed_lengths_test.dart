import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(MobileScannerController, _FakeMobileScannerPlatform)> pumpScanner(
    WidgetTester tester, {
    required Set<int> allowedLengths,
  }) async {
    final fakePlatform = _FakeMobileScannerPlatform();
    MobileScannerPlatform.instance = fakePlatform;

    final controller = MobileScannerController(allowedLengths: allowedLengths);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MobileScanner(controller: controller))),
    );
    await tester.pumpAndSettle();

    return (controller, fakePlatform);
  }

  testWidgets('empty allowedLengths forwards every barcode capture unchanged', (
    tester,
  ) async {
    final (controller, fakePlatform) = await pumpScanner(
      tester,
      allowedLengths: const <int>{},
    );
    addTearDown(controller.dispose);

    final received = <BarcodeCapture>[];
    final subscription = controller.barcodes.listen(received.add);
    addTearDown(subscription.cancel);

    const capture = BarcodeCapture(
      barcodes: [
        Barcode(rawValue: '12345'),
        Barcode(rawValue: '12345678901234'),
      ],
    );
    fakePlatform.addBarcode(capture);
    await tester.pumpAndSettle();

    expect(received, hasLength(1));
    expect(identical(received.single, capture), isTrue);
  });

  testWidgets(
    'allowedLengths drops barcodes whose rawValue length is not allowed',
    (tester) async {
      final (controller, fakePlatform) = await pumpScanner(
        tester,
        allowedLengths: const {14},
      );
      addTearDown(controller.dispose);

      final received = <BarcodeCapture>[];
      final subscription = controller.barcodes.listen(received.add);
      addTearDown(subscription.cancel);

      fakePlatform.addBarcode(
        const BarcodeCapture(
          barcodes: [
            Barcode(rawValue: '12345'),
            Barcode(rawValue: '12345678901234'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(received, hasLength(1));
      expect(received.single.barcodes.map((b) => b.rawValue).toList(), const [
        '12345678901234',
      ]);
    },
  );

  testWidgets('allowedLengths suppresses captures with no surviving barcodes', (
    tester,
  ) async {
    final (controller, fakePlatform) = await pumpScanner(
      tester,
      allowedLengths: const {14},
    );
    addTearDown(controller.dispose);

    final received = <BarcodeCapture>[];
    final subscription = controller.barcodes.listen(received.add);
    addTearDown(subscription.cancel);

    fakePlatform.addBarcode(
      const BarcodeCapture(barcodes: [Barcode(rawValue: '12345')]),
    );
    fakePlatform.addBarcode(
      const BarcodeCapture(barcodes: [Barcode(rawValue: '12345678901234')]),
    );
    await tester.pumpAndSettle();

    expect(received, hasLength(1));
    expect(received.single.barcodes.single.rawValue, '12345678901234');
  });

  testWidgets('allowedLengths drops barcodes whose rawValue is null', (
    tester,
  ) async {
    final (controller, fakePlatform) = await pumpScanner(
      tester,
      allowedLengths: const {14},
    );
    addTearDown(controller.dispose);

    final received = <BarcodeCapture>[];
    final subscription = controller.barcodes.listen(received.add);
    addTearDown(subscription.cancel);

    fakePlatform.addBarcode(
      const BarcodeCapture(
        barcodes: [Barcode(), Barcode(rawValue: '12345678901234')],
      ),
    );
    await tester.pumpAndSettle();

    expect(received, hasLength(1));
    expect(received.single.barcodes, hasLength(1));
    expect(received.single.barcodes.single.rawValue, '12345678901234');
  });

  testWidgets('analyzeImage applies allowedLengths to the platform result', (
    tester,
  ) async {
    final (controller, fakePlatform) = await pumpScanner(
      tester,
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

  testWidgets(
    'analyzeImage returns null when every barcode is dropped by allowedLengths',
    (tester) async {
      final (controller, fakePlatform) = await pumpScanner(
        tester,
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

  testWidgets('analyzeImage propagates a null platform result', (tester) async {
    final (controller, fakePlatform) = await pumpScanner(
      tester,
      allowedLengths: const {14},
    );
    addTearDown(controller.dispose);

    fakePlatform.nextAnalyzeImageResult = null;

    final result = await controller.analyzeImage('ignored.png');

    expect(result, isNull);
  });
}

class _FakeMobileScannerPlatform extends MobileScannerPlatform {
  final StreamController<BarcodeCapture> _barcodeStreamController =
      StreamController<BarcodeCapture>.broadcast();

  BarcodeCapture? nextAnalyzeImageResult;

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodeStreamController.stream;

  @override
  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) async {
    return nextAnalyzeImageResult;
  }

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

  void addBarcode(BarcodeCapture barcodeCapture) {
    _barcodeStreamController.add(barcodeCapture);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> dispose() {
    return _barcodeStreamController.close();
  }
}
