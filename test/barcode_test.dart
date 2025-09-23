import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';

void main() {
  group('scaleCorners', () {
    test('returns empty list if barcode has no size or corners', () {
      const Barcode barcode = Barcode();

      expect(barcode.scaleCorners(const Size(100, 100)), isEmpty);
    });

    test('returns empty list if barcode has no corners', () {
      const Barcode barcode = Barcode(size: Size(200, 200));

      expect(barcode.scaleCorners(const Size(100, 100)), isEmpty);
    });

    test('returns zeroed corners if barcode has corners but no size', () {
      const Barcode barcode = Barcode(
        corners: [Offset.zero, Offset.zero, Offset.zero, Offset.zero],
      );

      expect(barcode.scaleCorners(const Size(100, 100)), [
        Offset.zero,
        Offset.zero,
        Offset.zero,
        Offset.zero,
      ]);
    });

    test('returns zeroed corners if target size is empty', () {
      const Barcode barcode = Barcode(
        size: Size(200, 200),
        corners: [
          Offset(50, 50),
          Offset(150, 50),
          Offset(150, 150),
          Offset(50, 150),
        ],
      );

      expect(barcode.scaleCorners(Size.zero), [
        Offset.zero,
        Offset.zero,
        Offset.zero,
        Offset.zero,
      ]);
    });

    test('returns scaled corners', () {
      const Barcode barcode = Barcode(
        size: Size(100, 100),
        corners: [
          Offset(25, 25),
          Offset(75, 25),
          Offset(75, 75),
          Offset(25, 75),
        ],
      );

      expect(barcode.scaleCorners(const Size(200, 200)), const [
        Offset(50, 50),
        Offset(150, 50),
        Offset(150, 150),
        Offset(50, 150),
      ]);
    });
  });
}
