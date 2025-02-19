import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/overlay/barcode_painter.dart';
import 'package:mocktail/mocktail.dart';

class MockCanvas extends Mock implements Canvas {}

void main() {
  setUpAll(() {
    registerFallbackValue(Paint());
    registerFallbackValue(Offset.zero);
  });

  group('BarcodePainter Tests', () {
    test('shouldRepaint returns true when properties change', () {
      const painter1 = BarcodePainter(
        barcodeCorners: [
          Offset(10, 10),
          Offset(20, 10),
          Offset(20, 20),
          Offset(10, 20),
        ],
        barcodeSize: Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
      );

      const painter2 = BarcodePainter(
        barcodeCorners: [
          Offset(15, 10),
          Offset(25, 10),
          Offset(25, 20),
          Offset(15, 20),
        ],
        barcodeSize: Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: Size(200, 200),
        color: Colors.red, // Changed color
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when properties are the same', () {
      const painter1 = BarcodePainter(
        barcodeCorners: [
          Offset(10, 10),
          Offset(20, 10),
          Offset(20, 20),
          Offset(10, 20),
        ],
        barcodeSize: Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
      );

      const painter2 = BarcodePainter(
        barcodeCorners: [
          Offset(10, 10),
          Offset(20, 10),
          Offset(20, 20),
          Offset(10, 20),
        ],
        barcodeSize: Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('calculateBoxFitRatio works correctly', () {
      expect(
        calculateBoxFitRatio(
          BoxFit.fill,
          const Size(200, 100),
          const Size(400, 200),
        ),
        (widthRatio: 2.0, heightRatio: 2.0),
      );

      expect(
        calculateBoxFitRatio(
          BoxFit.contain,
          const Size(200, 100),
          const Size(400, 400),
        ),
        (widthRatio: 2.0, heightRatio: 2.0),
      );

      expect(
        calculateBoxFitRatio(
          BoxFit.cover,
          const Size(200, 100),
          const Size(400, 400),
        ),
        (widthRatio: 4.0, heightRatio: 4.0),
      );

      expect(
        calculateBoxFitRatio(
          BoxFit.fitWidth,
          const Size(200, 100),
          const Size(400, 400),
        ),
        (widthRatio: 2.0, heightRatio: 2.0),
      );

      expect(
        calculateBoxFitRatio(
          BoxFit.fitHeight,
          const Size(200, 100),
          const Size(400, 400),
        ),
        (widthRatio: 4.0, heightRatio: 4.0),
      );

      expect(
        calculateBoxFitRatio(
          BoxFit.none,
          const Size(200, 100),
          const Size(400, 400),
        ),
        (widthRatio: 1.0, heightRatio: 1.0),
      );

      expect(
        calculateBoxFitRatio(
          BoxFit.scaleDown,
          const Size(200, 100),
          const Size(400, 400),
        ),
        (widthRatio: 1.0, heightRatio: 1.0),
      );
    });

    test('paint does not crash when barcodeCorners is invalid', () {
      final mockCanvas = MockCanvas();
      const painter = BarcodePainter(
        barcodeCorners: [],
        barcodeSize: Size.zero,
        boxFit: BoxFit.contain,
        cameraPreviewSize: Size.zero,
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '',
      );

      expect(
        () => painter.paint(mockCanvas, const Size(200, 200)),
        returnsNormally,
      );
    });
  });
}
