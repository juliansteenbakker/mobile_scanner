import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// TODO(navaronbracke): add test for when controller is provided to widget
// (detect barcodes / dispose controller)
// TODO(navaronbracke): test for existence of error widget, if start fails

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onDetect is notified of scanned barcodes', (
    tester,
  ) async {
    final fakePlatform = FakeMobileScannerPlatform();

    MobileScannerPlatform.instance = fakePlatform;

    BarcodeCapture? value;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileScanner(
            onDetect: (barcodes) {
              value = barcodes;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const barcodeCapture = BarcodeCapture(
      barcodes: [Barcode(rawValue: '12345')],
    );

    fakePlatform.addBarcode(barcodeCapture);
    await tester.pumpAndSettle();

    expect(value, barcodeCapture);
  });
}

class FakeMobileScannerPlatform extends MobileScannerPlatform {
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
  Future<void> dispose() {
    return _barcodeStreamController.close();
  }
}
