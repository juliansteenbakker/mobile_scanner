import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/overlay/barcode_painter.dart';

void main() {
  testWidgets('BarcodePainter draws barcode outline and text correctly', (
    tester,
  ) async {
    final painterKey = UniqueKey();
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final barcodePainter = BarcodePainter(
      barcodeCorners: [
        const Offset(10, 10),
        const Offset(60, 10),
        const Offset(60, 60),
        const Offset(10, 60),
      ],
      barcodeSize: const Size(50, 50),
      boxFit: BoxFit.contain,
      cameraPreviewSize: const Size(200, 200),
      color: Colors.blue,
      style: PaintingStyle.stroke,
      barcodeValue: '123456',
      textPainter: textPainter,
      deviceOrientation: DeviceOrientation.portraitUp,
    );

    addTearDown(textPainter.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            key: painterKey,
            size: const Size(200, 200),
            painter: barcodePainter,
          ),
        ),
      ),
    );

    final box = tester.renderObject(find.byKey(painterKey));
    expect(
      box,
      paints
        ..path(color: Colors.blue, style: PaintingStyle.stroke, strokeWidth: 4)
        ..save()
        ..translate(x: 35, y: 35)
        ..rotate()
        ..translate(x: -35, y: -35)
        ..rrect()
        ..restore(),
    );
  });

  testWidgets('BarcodePainter should not draw if corners is invalid', (
    tester,
  ) async {
    final painterKey = UniqueKey();
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final barcodePainter = BarcodePainter(
      barcodeCorners: [],
      barcodeSize: const Size(50, 50),
      boxFit: BoxFit.contain,
      cameraPreviewSize: const Size(200, 200),
      color: Colors.blue,
      style: PaintingStyle.stroke,
      barcodeValue: '123456',
      textPainter: textPainter,
      deviceOrientation: DeviceOrientation.portraitUp,
    );

    addTearDown(textPainter.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            key: painterKey,
            size: const Size(200, 200),
            painter: barcodePainter,
          ),
        ),
      ),
    );

    final box = tester.renderObject(find.byKey(painterKey));

    expect(box, paintsNothing);
  });

  // TODO(navaronbracke): this does not test all combinations yet
  test('BarcodePainter shouldRepaint returns true when properties change', () {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final painter1 = BarcodePainter(
      barcodeCorners: [
        const Offset(10, 10),
        const Offset(20, 10),
        const Offset(20, 20),
        const Offset(10, 20),
      ],
      barcodeSize: const Size(100, 50),
      boxFit: BoxFit.contain,
      cameraPreviewSize: const Size(200, 200),
      color: Colors.blue,
      style: PaintingStyle.stroke,
      barcodeValue: '123456',
      textPainter: textPainter,
      deviceOrientation: DeviceOrientation.portraitUp,
    );

    final painter2 = BarcodePainter(
      barcodeCorners: [
        const Offset(15, 10),
        const Offset(25, 10),
        const Offset(25, 20),
        const Offset(15, 20),
      ],
      barcodeSize: const Size(100, 50),
      boxFit: BoxFit.contain,
      cameraPreviewSize: const Size(200, 200),
      color: Colors.red, // Changed color
      style: PaintingStyle.stroke,
      barcodeValue: '123456',
      textPainter: textPainter,
      deviceOrientation: DeviceOrientation.portraitUp,
    );

    addTearDown(textPainter.dispose);

    expect(painter1.shouldRepaint(painter2), isTrue);
  });

  test(
    'BarcodePainter shouldRepaint returns false when properties are the same',
    () {
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      final painter1 = BarcodePainter(
        barcodeCorners: [
          const Offset(10, 10),
          const Offset(20, 10),
          const Offset(20, 20),
          const Offset(10, 20),
        ],
        barcodeSize: const Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      final painter2 = BarcodePainter(
        barcodeCorners: [
          const Offset(10, 10),
          const Offset(20, 10),
          const Offset(20, 20),
          const Offset(10, 20),
        ],
        barcodeSize: const Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      addTearDown(textPainter.dispose);

      expect(painter1.shouldRepaint(painter2), isFalse);
    },
  );
}
