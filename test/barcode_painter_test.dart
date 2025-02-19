import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/overlay/barcode_painter.dart';
import 'package:mocktail/mocktail.dart';

class MockCanvas extends Mock implements Canvas {}

void main() {
  setUpAll(() {
    registerFallbackValue(Paint());
    registerFallbackValue(Offset.zero);
    registerFallbackValue(Path());
    registerFallbackValue(Rect.zero);
    registerFallbackValue(RRect.zero);
  });

  group('BarcodePainter Tests', () {
    testWidgets('paint should draw barcode outline and text correctly',
        (tester) async {
      final mockCanvas = MockCanvas();
      const barcodePainter = BarcodePainter(
        barcodeCorners: [
          Offset(10, 10),
          Offset(100, 10),
          Offset(100, 100),
          Offset(10, 100),
        ],
        barcodeSize: Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
      );

      // Act: Call the paint method
      barcodePainter.paint(mockCanvas, const Size(200, 200));

      // Assert: Verify drawing operations
      verify(() => mockCanvas.drawPath(any(), any())).called(1);
      verify(() => mockCanvas.drawRRect(any(), any())).called(1);
      verify(() => mockCanvas.save()).called(1);
      verify(() => mockCanvas.restore()).called(1);
    });

    testWidgets('paint should not draw if barcodeCorners is invalid',
        (tester) async {
      final mockCanvas = MockCanvas();
      const barcodePainter = BarcodePainter(
        barcodeCorners: [],
        barcodeSize: Size.zero,
        boxFit: BoxFit.contain,
        cameraPreviewSize: Size.zero,
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '',
      );

      barcodePainter.paint(mockCanvas, const Size(200, 200));

      // Verify that NO draw operations happen
      verifyNever(() => mockCanvas.drawPath(any(), any()));
      verifyNever(() => mockCanvas.drawRRect(any(), any()));
      verifyNever(() => mockCanvas.drawLine(any(), any(), any()));
    });

    testWidgets('paint should rotate text correctly', (tester) async {
      final mockCanvas = MockCanvas();
      const barcodePainter = BarcodePainter(
        barcodeCorners: [
          Offset(10, 10),
          Offset(100, 10),
          Offset(100, 100),
          Offset(10, 100),
        ],
        barcodeSize: Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
      );

      barcodePainter.paint(mockCanvas, const Size(200, 200));

      // Ensure text rotation is applied
      verify(() => mockCanvas.translate(any(), any())).called(2);
      verify(() => mockCanvas.rotate(any())).called(1);
    });

    testWidgets('shouldRepaint returns true when properties change',
        (tester) async {
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

    testWidgets('shouldRepaint returns false when properties are the same',
        (tester) async {
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
  });
}
