import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        deviceOrientation: DeviceOrientation.portraitUp,
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
        deviceOrientation: DeviceOrientation.portraitUp,
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
        deviceOrientation: DeviceOrientation.portraitUp,
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

    test(
      'calculateBoxFitRatio returns 1.0 for zero cameraPreviewSize width',
      () {
        expect(
          calculateBoxFitRatio(
            BoxFit.contain,
            const Size(0, 100),
            const Size(400, 400),
          ),
          (widthRatio: 1.0, heightRatio: 1.0),
        );
      },
    );

    test(
      'calculateBoxFitRatio returns 1.0 for zero cameraPreviewSize height',
      () {
        expect(
          calculateBoxFitRatio(
            BoxFit.contain,
            const Size(200, 0),
            const Size(400, 400),
          ),
          (widthRatio: 1.0, heightRatio: 1.0),
        );
      },
    );

    test('calculateBoxFitRatio returns 1.0 for zero target size width', () {
      expect(
        calculateBoxFitRatio(
          BoxFit.contain,
          const Size(200, 100),
          const Size(0, 400),
        ),
        (widthRatio: 1.0, heightRatio: 1.0),
      );
    });

    test('calculateBoxFitRatio returns 1.0 for zero target size height', () {
      expect(
        calculateBoxFitRatio(
          BoxFit.contain,
          const Size(200, 100),
          const Size(400, 0),
        ),
        (widthRatio: 1.0, heightRatio: 1.0),
      );
    });

    test(
      'calculateBoxFitRatio scaleDown scales down when content is larger',
      () {
        expect(
          calculateBoxFitRatio(
            BoxFit.scaleDown,
            const Size(800, 600),
            const Size(400, 300),
          ),
          (widthRatio: 0.5, heightRatio: 0.5),
        );
      },
    );

    testWidgets('paint handles landscapeLeft orientation', (tester) async {
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
        deviceOrientation: DeviceOrientation.landscapeLeft,
      ).paint(mockCanvas, const Size(200, 200));

      verify(() => mockCanvas.drawPath(any(), any())).called(1);
      verify(() => mockCanvas.drawRRect(any(), any())).called(1);
    });

    testWidgets('paint handles landscapeRight orientation', (tester) async {
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
        deviceOrientation: DeviceOrientation.landscapeRight,
      ).paint(mockCanvas, const Size(200, 200));

      verify(() => mockCanvas.drawPath(any(), any())).called(1);
      verify(() => mockCanvas.drawRRect(any(), any())).called(1);
    });

    testWidgets('paint handles portraitDown orientation', (tester) async {
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
        deviceOrientation: DeviceOrientation.portraitDown,
      ).paint(mockCanvas, const Size(200, 200));

      verify(() => mockCanvas.drawPath(any(), any())).called(1);
      verify(() => mockCanvas.drawRRect(any(), any())).called(1);
    });

    testWidgets('paint does not draw when barcodeSize is empty', (
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
        barcodeSize: Size.zero,
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      ).paint(mockCanvas, const Size(200, 200));

      verifyNever(() => mockCanvas.drawPath(any(), any()));
      verifyNever(() => mockCanvas.drawRRect(any(), any()));
    });

    testWidgets('paint does not draw when cameraPreviewSize is empty', (
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
        cameraPreviewSize: Size.zero,
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      ).paint(mockCanvas, const Size(200, 200));

      verifyNever(() => mockCanvas.drawPath(any(), any()));
      verifyNever(() => mockCanvas.drawRRect(any(), any()));
    });

    testWidgets('paint does not draw when corners has less than 4 elements', (
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
        ],
        barcodeSize: const Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      ).paint(mockCanvas, const Size(200, 200));

      verifyNever(() => mockCanvas.drawPath(any(), any()));
      verifyNever(() => mockCanvas.drawRRect(any(), any()));
    });

    testWidgets('shouldRepaint returns true when barcodeSize changes', (
      tester,
    ) async {
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      final corners = [
        const Offset(10, 10),
        const Offset(20, 10),
        const Offset(20, 20),
        const Offset(10, 20),
      ];

      final painter1 = BarcodePainter(
        barcodeCorners: corners,
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
        barcodeCorners: corners,
        barcodeSize: const Size(150, 75),
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    testWidgets('shouldRepaint returns true when boxFit changes', (
      tester,
    ) async {
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      final corners = [
        const Offset(10, 10),
        const Offset(20, 10),
        const Offset(20, 20),
        const Offset(10, 20),
      ];

      final painter1 = BarcodePainter(
        barcodeCorners: corners,
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
        barcodeCorners: corners,
        barcodeSize: const Size(100, 50),
        boxFit: BoxFit.cover,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    testWidgets('shouldRepaint returns true when cameraPreviewSize changes', (
      tester,
    ) async {
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      final corners = [
        const Offset(10, 10),
        const Offset(20, 10),
        const Offset(20, 20),
        const Offset(10, 20),
      ];

      final painter1 = BarcodePainter(
        barcodeCorners: corners,
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
        barcodeCorners: corners,
        barcodeSize: const Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(300, 300),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    testWidgets('shouldRepaint returns true when style changes', (
      tester,
    ) async {
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      final corners = [
        const Offset(10, 10),
        const Offset(20, 10),
        const Offset(20, 20),
        const Offset(10, 20),
      ];

      final painter1 = BarcodePainter(
        barcodeCorners: corners,
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
        barcodeCorners: corners,
        barcodeSize: const Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.fill,
        barcodeValue: '123456',
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    testWidgets('shouldRepaint returns true when barcodeValue changes', (
      tester,
    ) async {
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      final corners = [
        const Offset(10, 10),
        const Offset(20, 10),
        const Offset(20, 20),
        const Offset(10, 20),
      ];

      final painter1 = BarcodePainter(
        barcodeCorners: corners,
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
        barcodeCorners: corners,
        barcodeSize: const Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '654321',
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    testWidgets('shouldRepaint returns true when deviceOrientation changes', (
      tester,
    ) async {
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      final corners = [
        const Offset(10, 10),
        const Offset(20, 10),
        const Offset(20, 20),
        const Offset(10, 20),
      ];

      final painter1 = BarcodePainter(
        barcodeCorners: corners,
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
        barcodeCorners: corners,
        barcodeSize: const Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.landscapeLeft,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('BarcodePainter uses default strokeWidth', () {
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      final painter = BarcodePainter(
        barcodeCorners: const [Offset(10, 10)],
        barcodeSize: const Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      expect(painter.strokeWidth, 4.0);
    });

    test('BarcodePainter accepts custom strokeWidth', () {
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      final painter = BarcodePainter(
        barcodeCorners: const [Offset(10, 10)],
        barcodeSize: const Size(100, 50),
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.blue,
        style: PaintingStyle.stroke,
        barcodeValue: '123456',
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
        strokeWidth: 8,
      );

      expect(painter.strokeWidth, 8.0);
    });
  });
}
