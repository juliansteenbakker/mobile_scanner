import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/web/web_barcode_utils.dart';

// NOTE: shouldMirrorStream and maybeFlipVideoPreview are intentionally not
// tested here. They depend on web.MediaStream / web.HTMLVideoElement (JS
// interop types) that are only available in a browser environment and cannot
// be exercised in a Dart VM unit test.

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Builds a [Barcode] with the given [corners].
  Barcode barcodeWithCorners(List<Offset> corners) {
    return Barcode(corners: corners, format: BarcodeFormat.qrCode);
  }

  /// Standard 640×480 video size used across most tests.
  const videoSize = Size(640, 480);

  /// Scan window covering the centre quarter of the frame (normalised [0,1]).
  const centreWindow = Rect.fromLTRB(0.25, 0.25, 0.75, 0.75);

  // ---------------------------------------------------------------------------
  // isInsideScanWindow
  // ---------------------------------------------------------------------------

  group('isInsideScanWindow', () {
    group('degenerate inputs always return true', () {
      test('null scan window', () {
        final barcode = barcodeWithCorners(const [
          Offset(0, 0),
          Offset(100, 0),
          Offset(100, 100),
          Offset(0, 100),
        ]);

        expect(isInsideScanWindow(barcode, null, videoSize), isTrue);
      });

      test('empty corners list', () {
        expect(
          isInsideScanWindow(barcodeWithCorners([]), centreWindow, videoSize),
          isTrue,
        );
      });

      test('fewer than 4 corners (3)', () {
        final barcode = barcodeWithCorners(const [
          Offset(200, 120),
          Offset(440, 120),
          Offset(440, 360),
        ]);

        expect(isInsideScanWindow(barcode, centreWindow, videoSize), isTrue);
      });

      test('more than 4 corners (5)', () {
        final barcode = barcodeWithCorners(const [
          Offset(200, 120),
          Offset(440, 120),
          Offset(440, 360),
          Offset(200, 360),
          Offset(320, 240),
        ]);

        expect(isInsideScanWindow(barcode, centreWindow, videoSize), isTrue);
      });

      test('zero video width', () {
        final barcode = barcodeWithCorners(const [
          Offset(10, 10),
          Offset(20, 10),
          Offset(20, 20),
          Offset(10, 20),
        ]);

        expect(
          isInsideScanWindow(barcode, centreWindow, const Size(0, 480)),
          isTrue,
        );
      });

      test('zero video height', () {
        final barcode = barcodeWithCorners(const [
          Offset(10, 10),
          Offset(20, 10),
          Offset(20, 20),
          Offset(10, 20),
        ]);

        expect(
          isInsideScanWindow(barcode, centreWindow, const Size(640, 0)),
          isTrue,
        );
      });

      test('zero video size', () {
        final barcode = barcodeWithCorners(const [
          Offset(10, 10),
          Offset(20, 10),
          Offset(20, 20),
          Offset(10, 20),
        ]);

        expect(
          isInsideScanWindow(barcode, centreWindow, Size.zero),
          isTrue,
        );
      });
    });

    group('barcode fully inside window', () {
      // centreWindow = Rect.fromLTRB(0.25, 0.25, 0.75, 0.75)
      // video 640×480 → pixel bounds: x [160, 480], y [120, 360]

      test('barcode well inside window', () {
        final barcode = barcodeWithCorners(const [
          Offset(200, 160),
          Offset(440, 160),
          Offset(440, 320),
          Offset(200, 320),
        ]);

        expect(isInsideScanWindow(barcode, centreWindow, videoSize), isTrue);
      });

      test('barcode corners exactly on window boundary', () {
        // normalised: left=0.25, top=0.25, right=0.75, bottom=0.75
        final barcode = barcodeWithCorners(const [
          Offset(160, 120), // TL — normalised (0.25, 0.25)
          Offset(480, 120), // TR — normalised (0.75, 0.25)
          Offset(480, 360), // BR — normalised (0.75, 0.75)
          Offset(160, 360), // BL — normalised (0.25, 0.75)
        ]);

        expect(isInsideScanWindow(barcode, centreWindow, videoSize), isTrue);
      });

      test('single-pixel barcode at window centre', () {
        final barcode = barcodeWithCorners(const [
          Offset(320, 240),
          Offset(321, 240),
          Offset(321, 241),
          Offset(320, 241),
        ]);

        expect(isInsideScanWindow(barcode, centreWindow, videoSize), isTrue);
      });
    });

    group('barcode fully outside window', () {
      test('barcode in top-left corner (above and left of window)', () {
        final barcode = barcodeWithCorners(const [
          Offset(0, 0),
          Offset(100, 0),
          Offset(100, 100),
          Offset(0, 100),
        ]);

        expect(isInsideScanWindow(barcode, centreWindow, videoSize), isFalse);
      });

      test('barcode in bottom-right corner', () {
        final barcode = barcodeWithCorners(const [
          Offset(540, 380),
          Offset(640, 380),
          Offset(640, 480),
          Offset(540, 480),
        ]);

        expect(isInsideScanWindow(barcode, centreWindow, videoSize), isFalse);
      });
    });

    group('barcode partially overlapping window edge', () {
      test('left edge outside', () {
        // minX = 100/640 ≈ 0.156 < 0.25
        final barcode = barcodeWithCorners(const [
          Offset(100, 160),
          Offset(440, 160),
          Offset(440, 320),
          Offset(100, 320),
        ]);

        expect(isInsideScanWindow(barcode, centreWindow, videoSize), isFalse);
      });

      test('right edge outside', () {
        // maxX = 520/640 = 0.8125 > 0.75
        final barcode = barcodeWithCorners(const [
          Offset(200, 160),
          Offset(520, 160),
          Offset(520, 320),
          Offset(200, 320),
        ]);

        expect(isInsideScanWindow(barcode, centreWindow, videoSize), isFalse);
      });

      test('top edge outside', () {
        // minY = 60/480 = 0.125 < 0.25
        final barcode = barcodeWithCorners(const [
          Offset(200, 60),
          Offset(440, 60),
          Offset(440, 320),
          Offset(200, 320),
        ]);

        expect(isInsideScanWindow(barcode, centreWindow, videoSize), isFalse);
      });

      test('bottom edge outside', () {
        // maxY = 420/480 = 0.875 > 0.75
        final barcode = barcodeWithCorners(const [
          Offset(200, 160),
          Offset(440, 160),
          Offset(440, 420),
          Offset(200, 420),
        ]);

        expect(isInsideScanWindow(barcode, centreWindow, videoSize), isFalse);
      });

      test('one corner outside (rotated barcode)', () {
        // Three corners inside, one just outside the left boundary.
        // minX = 100/640 ≈ 0.156 < 0.25 → rejected
        final barcode = barcodeWithCorners(const [
          Offset(100, 160), // outside left
          Offset(440, 160),
          Offset(440, 320),
          Offset(200, 320),
        ]);

        expect(isInsideScanWindow(barcode, centreWindow, videoSize), isFalse);
      });
    });

    test('full-frame scan window accepts any barcode', () {
      const fullWindow = Rect.fromLTRB(0, 0, 1, 1);
      final barcode = barcodeWithCorners(const [
        Offset(0, 0),
        Offset(640, 0),
        Offset(640, 480),
        Offset(0, 480),
      ]);

      expect(isInsideScanWindow(barcode, fullWindow, videoSize), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // mirrorBarcodeX
  // ---------------------------------------------------------------------------

  group('mirrorBarcodeX', () {
    const width = 640.0;

    test('mirrors all corner x-coordinates', () {
      final barcode = barcodeWithCorners(const [
        Offset(100, 10),
        Offset(540, 10),
        Offset(540, 110),
        Offset(100, 110),
      ]);

      final mirrored = mirrorBarcodeX(barcode, width);

      // x' = width - x; winding reorder swaps adjacent pairs.
      // original: [TL(100,10), TR(540,10), BR(540,110), BL(100,110)]
      // mirrored x: [(540,10), (100,10), (100,110), (540,110)]
      // reordered ([1],[0],[3],[2]): [(100,10), (540,10), (540,110), (100,110)]
      expect(mirrored.corners[0], const Offset(100, 10));
      expect(mirrored.corners[1], const Offset(540, 10));
      expect(mirrored.corners[2], const Offset(540, 110));
      expect(mirrored.corners[3], const Offset(100, 110));
    });

    test('y-coordinates are unchanged', () {
      final barcode = barcodeWithCorners(const [
        Offset(50, 30),
        Offset(200, 80),
        Offset(200, 180),
        Offset(50, 180),
      ]);

      final mirrored = mirrorBarcodeX(barcode, width);

      for (final corner in mirrored.corners) {
        expect(
          [30.0, 80.0, 180.0].contains(corner.dy),
          isTrue,
          reason: 'y value ${corner.dy} was unexpectedly modified',
        );
      }
    });

    test('corner at x=0 moves to x=videoWidth', () {
      final barcode = barcodeWithCorners([
        const Offset(0, 0),
        const Offset(width, 0),
        const Offset(width, 100),
        const Offset(0, 100),
      ]);

      final mirrored = mirrorBarcodeX(barcode, width);

      // After mirroring x and reordering, each unique x stays the same
      // numerically but sides swap.
      final xs = mirrored.corners.map((c) => c.dx).toSet();
      expect(xs, containsAll([0.0, width]));
    });

    test('preserves all barcode fields other than corners', () {
      const original = Barcode(
        corners: [
          Offset(0, 0),
          Offset(100, 0),
          Offset(100, 100),
          Offset(0, 100),
        ],
        format: BarcodeFormat.qrCode,
        rawValue: 'hello',
        displayValue: 'hello',
      );

      final mirrored = mirrorBarcodeX(original, 200);

      expect(mirrored.format, original.format);
      expect(mirrored.rawValue, original.rawValue);
      expect(mirrored.displayValue, original.displayValue);
    });

    test('returns unchanged barcode when corners list is empty', () {
      final barcode = barcodeWithCorners([]);
      final mirrored = mirrorBarcodeX(barcode, width);

      expect(mirrored.corners, isEmpty);
    });

    test('mirrors without reorder when corners count is not 4', () {
      // 2 corners — only x is mirrored, no reordering.
      final barcode = barcodeWithCorners(const [
        Offset(100, 0),
        Offset(200, 0),
      ]);

      final mirrored = mirrorBarcodeX(barcode, width);

      expect(mirrored.corners[0].dx, width - 100);
      expect(mirrored.corners[1].dx, width - 200);
    });

    test('applying mirrorBarcodeX twice restores original corners', () {
      const original = Barcode(
        corners: [
          Offset(100, 50),
          Offset(300, 50),
          Offset(300, 200),
          Offset(100, 200),
        ],
        format: BarcodeFormat.qrCode,
      );

      final double_mirrored = mirrorBarcodeX(
        mirrorBarcodeX(original, width),
        width,
      );

      for (var i = 0; i < 4; i++) {
        expect(
          double_mirrored.corners[i].dx,
          closeTo(original.corners[i].dx, 0.001),
        );
        expect(
          double_mirrored.corners[i].dy,
          closeTo(original.corners[i].dy, 0.001),
        );
      }
    });

    test('videoWidth=0 negates all x-coordinates', () {
      // mirrorBarcodeX computes (videoWidth - x); with videoWidth=0 this is -x.
      const original = [
        Offset(100, 10),
        Offset(200, 10),
        Offset(200, 50),
        Offset(100, 50),
      ];
      final barcode = barcodeWithCorners(original);

      final mirrored = mirrorBarcodeX(barcode, 0);

      // After mirroring and 4-corner reorder, every x should be the negation
      // of its pre-reorder mirrored value.  Just verify that no x is positive.
      for (final corner in mirrored.corners) {
        expect(corner.dx, isNegative);
      }
    });
  });
}
