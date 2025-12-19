import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/overlay/scan_window_painter.dart';
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

  group('ScanWindowPainter', () {
    group('paint', () {
      test('does not paint when scanWindow is empty', () {
        final mockCanvas = MockCanvas();

        const ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2,
          color: Colors.black,
          scanWindow: Rect.zero,
        ).paint(mockCanvas, const Size(400, 800));

        verifyNever(() => mockCanvas.drawPath(any(), any()));
        verifyNever(() => mockCanvas.drawRRect(any(), any()));
      });

      test('does not paint when scanWindow is infinite', () {
        final mockCanvas = MockCanvas();

        const ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2,
          color: Colors.black,
          scanWindow: Rect.fromLTWH(0, 0, double.infinity, double.infinity),
        ).paint(mockCanvas, const Size(400, 800));

        verifyNever(() => mockCanvas.drawPath(any(), any()));
        verifyNever(() => mockCanvas.drawRRect(any(), any()));
      });

      test('paints overlay and border when scanWindow is valid', () {
        final mockCanvas = MockCanvas();

        const ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2,
          color: Color(0x80000000),
          scanWindow: Rect.fromLTWH(50, 100, 300, 300),
        ).paint(mockCanvas, const Size(400, 800));

        verify(() => mockCanvas.drawPath(any(), any())).called(1);
        verify(() => mockCanvas.drawRRect(any(), any())).called(1);
      });

      test('paints with border radius when specified', () {
        final mockCanvas = MockCanvas();

        const ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderStrokeCap: StrokeCap.round,
          borderStrokeJoin: StrokeJoin.round,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 4,
          color: Color(0x80000000),
          scanWindow: Rect.fromLTWH(50, 100, 300, 300),
        ).paint(mockCanvas, const Size(400, 800));

        verify(() => mockCanvas.drawPath(any(), any())).called(1);
        verify(() => mockCanvas.drawRRect(any(), any())).called(1);
      });

      test('paints with asymmetric border radius', () {
        final mockCanvas = MockCanvas();

        const ScanWindowPainter(
          borderColor: Colors.blue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(32),
          ),
          borderStrokeCap: StrokeCap.square,
          borderStrokeJoin: StrokeJoin.bevel,
          borderStyle: PaintingStyle.fill,
          borderWidth: 3,
          color: Color(0x40FF0000),
          scanWindow: Rect.fromLTWH(100, 200, 200, 400),
        ).paint(mockCanvas, const Size(400, 800));

        verify(() => mockCanvas.drawPath(any(), any())).called(1);
        verify(() => mockCanvas.drawRRect(any(), any())).called(1);
      });
    });

    group('shouldRepaint', () {
      test('returns true when scanWindow changes', () {
        const painter1 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2,
          color: Colors.black,
          scanWindow: Rect.fromLTWH(50, 100, 300, 300),
        );

        const painter2 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2,
          color: Colors.black,
          scanWindow: Rect.fromLTWH(60, 100, 300, 300),
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns true when color changes', () {
        const painter1 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2,
          color: Colors.black,
          scanWindow: Rect.fromLTWH(50, 100, 300, 300),
        );

        const painter2 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2,
          color: Colors.red,
          scanWindow: Rect.fromLTWH(50, 100, 300, 300),
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns true when borderRadius changes', () {
        const painter1 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2,
          color: Colors.black,
          scanWindow: Rect.fromLTWH(50, 100, 300, 300),
        );

        const painter2 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2,
          color: Colors.black,
          scanWindow: Rect.fromLTWH(50, 100, 300, 300),
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns false when properties are identical', () {
        const painter1 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2,
          color: Colors.black,
          scanWindow: Rect.fromLTWH(50, 100, 300, 300),
        );

        const painter2 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2,
          color: Colors.black,
          scanWindow: Rect.fromLTWH(50, 100, 300, 300),
        );

        expect(painter1.shouldRepaint(painter2), isFalse);
      });

      test('returns false when only unchanged properties differ', () {
        const painter1 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2,
          color: Colors.black,
          scanWindow: Rect.fromLTWH(50, 100, 300, 300),
        );

        const painter2 = ScanWindowPainter(
          borderColor: Colors.red,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.round,
          borderStrokeJoin: StrokeJoin.round,
          borderStyle: PaintingStyle.fill,
          borderWidth: 10,
          color: Colors.black,
          scanWindow: Rect.fromLTWH(50, 100, 300, 300),
        );

        expect(painter1.shouldRepaint(painter2), isFalse);
      });
    });
  });
}
