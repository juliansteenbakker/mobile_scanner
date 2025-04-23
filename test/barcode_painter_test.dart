import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/overlay/barcode_painter.dart';
import 'package:mocktail/mocktail.dart';

class MockCanvas extends Mock implements Canvas {}

class MockTextPainter extends Mock implements TextPainter {}

void main() {
  setUpAll(() {
    registerFallbackValue(Paint());
    registerFallbackValue(Offset.zero);
    registerFallbackValue(Path());
    registerFallbackValue(Rect.zero);
    registerFallbackValue(RRect.zero);
    registerFallbackValue(MockTextPainter());
  });

  group('BarcodePainter Tests', () {
    testWidgets('paint should draw barcode outline and text correctly', (
      tester,
    ) async {
      final mockCanvas = MockCanvas();
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      BarcodePainter(
        barcodeCorners: [
          const Offset(10, 10),
          const Offset(100, 10),
          const Offset(100, 100),
          const Offset(10, 100),
        ],
        barcodeSize: const Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
        textPainter: textPainter,
      )
      // Act: Call the paint method
      .paint(mockCanvas, const Size(200, 200));

      // Assert: Verify drawing operations
      verify(() => mockCanvas.drawPath(any(), any())).called(1);
      verify(() => mockCanvas.drawRRect(any(), any())).called(1);
      verify(mockCanvas.save).called(1);
      verify(mockCanvas.restore).called(1);
    });

    testWidgets('paint should not draw if barcodeCorners is invalid', (
      tester,
    ) async {
      final mockCanvas = MockCanvas();
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      BarcodePainter(
        barcodeCorners: [],
        barcodeSize: Size.zero,
        boxFit: BoxFit.contain,
        cameraPreviewSize: Size.zero,
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '',
        textPainter: textPainter,
      ).paint(mockCanvas, const Size(200, 200));

      // Verify that NO draw operations happen
      verifyNever(() => mockCanvas.drawPath(any(), any()));
      verifyNever(() => mockCanvas.drawRRect(any(), any()));
      verifyNever(() => mockCanvas.drawLine(any(), any(), any()));
    });

    testWidgets('paint should rotate text correctly', (tester) async {
      final mockCanvas = MockCanvas();
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      BarcodePainter(
        barcodeCorners: [
          const Offset(10, 10),
          const Offset(100, 10),
          const Offset(100, 100),
          const Offset(10, 100),
        ],
        barcodeSize: const Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
        textPainter: textPainter,
      ).paint(mockCanvas, const Size(200, 200));

      // Ensure text rotation is applied
      verify(() => mockCanvas.translate(any(), any())).called(2);
      verify(() => mockCanvas.rotate(any())).called(1);
    });

    testWidgets('shouldRepaint returns true when properties change', (
      tester,
    ) async {
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
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    testWidgets('shouldRepaint returns false when properties are the same', (
      tester,
    ) async {
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
