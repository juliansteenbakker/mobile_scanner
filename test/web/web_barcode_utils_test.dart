import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/web/web_barcode_utils.dart';

void main() {
  group('computeBoundingBoxSize', () {
    test('returns the bounding box size of four corners', () {
      const corners = [
        Offset(10, 20),
        Offset(110, 20),
        Offset(110, 70),
        Offset(10, 70),
      ];

      expect(computeBoundingBoxSize(corners), const Size(100, 50));
    });

    test('handles rotated (non-axis-aligned) corners', () {
      const corners = [
        Offset(50, 0),
        Offset(100, 50),
        Offset(50, 100),
        Offset(0, 50),
      ];

      expect(computeBoundingBoxSize(corners), const Size(100, 100));
    });

    test('returns Size.zero when there are not exactly four corners', () {
      expect(computeBoundingBoxSize(const []), Size.zero);
      expect(computeBoundingBoxSize(const [Offset.zero]), Size.zero);
      expect(
        computeBoundingBoxSize(const [
          Offset.zero,
          Offset(1, 1),
          Offset(2, 2),
          Offset(3, 3),
          Offset(4, 4),
        ]),
        Size.zero,
      );
    });
  });
}
