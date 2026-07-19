import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/overlay/scan_window_painter.dart';

/// Builds a [ScanWindowPainter] with sensible defaults so individual tests
/// only have to override what they care about.
ScanWindowPainter _painter({
  Color borderColor = Colors.white,
  BorderRadius borderRadius = BorderRadius.zero,
  StrokeCap borderStrokeCap = StrokeCap.round,
  StrokeJoin borderStrokeJoin = StrokeJoin.round,
  PaintingStyle borderStyle = PaintingStyle.stroke,
  double borderWidth = 2.0,
  Color color = Colors.black54,
  Rect scanWindow = const Rect.fromLTWH(50, 50, 100, 100),
}) {
  return ScanWindowPainter(
    borderColor: borderColor,
    borderRadius: borderRadius,
    borderStrokeCap: borderStrokeCap,
    borderStrokeJoin: borderStrokeJoin,
    borderStyle: borderStyle,
    borderWidth: borderWidth,
    color: color,
    scanWindow: scanWindow,
  );
}

void main() {
  group('ScanWindowPainter paint', () {
    testWidgets('does not paint when scanWindow is empty', (tester) async {
      final key = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: CustomPaint(
            key: key,
            size: const Size(300, 300),
            painter: _painter(scanWindow: Rect.zero),
          ),
        ),
      );

      expect(tester.renderObject(find.byKey(key)), paintsNothing);
    });

    testWidgets('does not paint when scanWindow is infinite', (tester) async {
      final key = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: CustomPaint(
            key: key,
            size: const Size(300, 300),
            painter: _painter(
              scanWindow: const Rect.fromLTRB(
                double.negativeInfinity,
                double.negativeInfinity,
                double.infinity,
                double.infinity,
              ),
            ),
          ),
        ),
      );

      expect(tester.renderObject(find.byKey(key)), paintsNothing);
    });

    testWidgets('paints overlay and border with BorderRadius.zero', (
      tester,
    ) async {
      final key = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: CustomPaint(
            key: key,
            size: const Size(300, 300),
            painter: _painter(),
          ),
        ),
      );

      final box = tester.renderObject(find.byKey(key));

      // Expect a saveLayer, the full-frame colour fill, the clear cutout,
      // restore, and finally the border RRect.
      expect(
        box,
        paints
          ..rect(color: Colors.black54)
          ..rrect()
          ..restore()
          ..rrect(color: Colors.white),
      );
    });

    testWidgets('paints overlay and border with non-zero BorderRadius', (
      tester,
    ) async {
      final key = UniqueKey();
      final radius = BorderRadius.circular(12);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomPaint(
            key: key,
            size: const Size(300, 300),
            painter: _painter(borderRadius: radius),
          ),
        ),
      );

      final box = tester.renderObject(find.byKey(key));

      expect(
        box,
        paints
          ..rect(color: Colors.black54)
          ..rrect()
          ..restore()
          ..rrect(color: Colors.white),
      );
    });
  });

  group('ScanWindowPainter shouldRepaint', () {
    test('returns true when scanWindow changes', () {
      final p1 = _painter(scanWindow: const Rect.fromLTWH(0, 0, 100, 100));
      final p2 = _painter(scanWindow: const Rect.fromLTWH(10, 10, 80, 80));

      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('returns true when color changes', () {
      final p1 = _painter();
      final p2 = _painter(color: Colors.red);

      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('returns true when borderRadius changes', () {
      final p1 = _painter();
      final p2 = _painter(borderRadius: BorderRadius.circular(8));

      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('returns false when nothing changes', () {
      final p1 = _painter();
      final p2 = _painter();

      expect(p1.shouldRepaint(p2), isFalse);
    });
  });
}
