import 'dart:async';

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

  Future<MobileScannerController> pumpScanner(
    WidgetTester tester, {
    required Set<int> allowedLengths,
  }) async {
    final controller = MobileScannerController(allowedLengths: allowedLengths);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          height: 200,
          child: MobileScanner(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return controller;
  }

  testWidgets('empty allowedLengths forwards every barcode capture unchanged', (
    tester,
  ) async {
    final controller = await pumpScanner(tester, allowedLengths: const <int>{});
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
      final controller = await pumpScanner(tester, allowedLengths: const {14});
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

  testWidgets(
    'allowedLengths suppresses captures when no barcodes survive the filter',
    (tester) async {
      final controller = await pumpScanner(tester, allowedLengths: const {14});
      addTearDown(controller.dispose);

      final received = <BarcodeCapture>[];
      final subscription = controller.barcodes.listen(received.add);
      addTearDown(subscription.cancel);

      fakePlatform.addBarcode(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: '12345'), Barcode(rawValue: '678')],
        ),
      );
      await tester.pumpAndSettle();

      expect(received, isEmpty);
    },
  );

  testWidgets('allowedLengths drops barcodes whose rawValue is null', (
    tester,
  ) async {
    final controller = await pumpScanner(tester, allowedLengths: const {14});
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
}

class _FakeMobileScannerPlatform extends MobileScannerPlatform {
  final StreamController<BarcodeCapture> _barcodeStreamController =
      StreamController<BarcodeCapture>.broadcast();

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodeStreamController.stream;

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
