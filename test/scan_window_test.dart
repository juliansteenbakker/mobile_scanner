import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/scan_window_calculation.dart';

void main() {
  group('Scan window relative to texture', () {
    group('Landscape widget inside portrait texture', () {
      const textureSize = Size(480, 640);
      const widgetSize = Size(432, 256);
      final ctx = ScanWindowTestContext(
        textureSize: textureSize,
        widgetSize: widgetSize,
        scanWindow: Rect.fromLTWH(
          widgetSize.width / 4,
          widgetSize.height / 4,
          widgetSize.width / 2,
          widgetSize.height / 2,
        ),
      );

      final List<Map<String, Object>> testCases = [
        {
          'name': 'BoxFit.none',
          'fit': BoxFit.none,
          'expected': const Rect.fromLTRB(0.275, 0.4, 0.725, 0.6),
        },
        {
          'name': 'BoxFit.fill',
          'fit': BoxFit.fill,
          'expected': const Rect.fromLTRB(0.25, 0.25, 0.75, 0.75),
        },
        {
          'name': 'BoxFit.fitHeight',
          'fit': BoxFit.fitHeight,
          'expected': const Rect.fromLTRB(0, 0.25, 1, 0.75),
        },
        {
          'name': 'BoxFit.fitWidth',
          'fit': BoxFit.fitWidth,
          'expected': const Rect.fromLTRB(
            0.25,
            0.38888888888888895,
            0.75,
            0.6111111111111112,
          ),
        },
        {
          'name': 'BoxFit.cover',
          'fit': BoxFit.cover,
          'expected': const Rect.fromLTRB(
            0.25,
            0.38888888888888895,
            0.75,
            0.6111111111111112,
          ),
        },
        {
          'name': 'BoxFit.contain',
          'fit': BoxFit.contain,
          'expected': const Rect.fromLTRB(0, 0.25, 1, 0.75),
        },
        {
          'name': 'BoxFit.scaleDown',
          'fit': BoxFit.scaleDown,
          'expected': const Rect.fromLTRB(0, 0.25, 1, 0.75),
        },
      ];

      for (final testCase in testCases) {
        test('${testCase['name']} scaling', () {
          ctx.testScanWindow(
            testCase['fit']! as BoxFit,
            testCase['expected']! as Rect,
          );
        });
      }
    });

    group('Landscape widget inside landscape texture', () {
      const textureSize = Size(640, 480);
      const widgetSize = Size(320, 120);
      final ctx = ScanWindowTestContext(
        textureSize: textureSize,
        widgetSize: widgetSize,
        scanWindow: Rect.fromLTWH(
          widgetSize.width / 4,
          widgetSize.height / 4,
          widgetSize.width / 2,
          widgetSize.height / 2,
        ),
      );

      final List<Map<String, Object>> testCases = [
        {
          'name': 'BoxFit.none',
          'fit': BoxFit.none,
          'expected': const Rect.fromLTRB(0.375, 0.4375, 0.625, 0.5625),
        },
        {
          'name': 'BoxFit.fill',
          'fit': BoxFit.fill,
          'expected': const Rect.fromLTRB(0.25, 0.25, 0.75, 0.75),
        },
        {
          'name': 'BoxFit.fitHeight',
          'fit': BoxFit.fitHeight,
          'expected': const Rect.fromLTRB(0, 0.25, 1, 0.75),
        },
        {
          'name': 'BoxFit.fitWidth',
          'fit': BoxFit.fitWidth,
          'expected': const Rect.fromLTRB(0.25, 0.375, 0.75, 0.625),
        },
        {
          'name': 'BoxFit.cover',
          'fit': BoxFit.cover,
          'expected': const Rect.fromLTRB(0.25, 0.375, 0.75, 0.625),
        },
        {
          'name': 'BoxFit.contain',
          'fit': BoxFit.contain,
          'expected': const Rect.fromLTRB(0, 0.25, 1, 0.75),
        },
        {
          'name': 'BoxFit.scaleDown',
          'fit': BoxFit.scaleDown,
          'expected': const Rect.fromLTRB(0, 0.25, 1, 0.75),
        },
      ];

      for (final testCase in testCases) {
        test('${testCase['name']} scaling', () {
          ctx.testScanWindow(
            testCase['fit']! as BoxFit,
            testCase['expected']! as Rect,
          );
        });
      }
    });
  });

  group('calculateBoxFitRatio', () {
    group('Standard cases', () {
      final List<Map<String, Object>> testCases = [
        {
          'name': 'BoxFit.fill',
          'boxFit': BoxFit.fill,
          'expectedWidth': 0.9,
          'expectedHeight': 0.4,
        },
        {
          'name': 'BoxFit.contain',
          'boxFit': BoxFit.contain,
          'expectedWidth': 0.4,
          'expectedHeight': 0.4,
        },
        {
          'name': 'BoxFit.cover',
          'boxFit': BoxFit.cover,
          'expectedWidth': 0.9,
          'expectedHeight': 0.9,
        },
        {
          'name': 'BoxFit.fitWidth',
          'boxFit': BoxFit.fitWidth,
          'expectedWidth': 0.9,
          'expectedHeight': 0.9,
        },
        {
          'name': 'BoxFit.fitHeight',
          'boxFit': BoxFit.fitHeight,
          'expectedWidth': 0.4,
          'expectedHeight': 0.4,
        },
        {
          'name': 'BoxFit.none',
          'boxFit': BoxFit.none,
          'expectedWidth': 1.0,
          'expectedHeight': 1.0,
        },
        {
          'name': 'BoxFit.scaleDown',
          'boxFit': BoxFit.scaleDown,
          'expectedWidth': 0.4,
          'expectedHeight': 0.4,
        },
      ];

      const cameraPreviewSize = Size(480, 640);
      const size = Size(432, 256);

      for (final testCase in testCases) {
        test('${testCase['name']} scaling', () {
          final ({double heightRatio, double widthRatio}) ratio =
              calculateBoxFitRatio(
                testCase['boxFit']! as BoxFit,
                cameraPreviewSize,
                size,
              );
          expect(ratio.widthRatio, testCase['expectedWidth']);
          expect(ratio.heightRatio, testCase['expectedHeight']);
        });
      }
    });

    group('Edge cases', () {
      test('Zero width/height in cameraPreviewSize', () {
        final ({double heightRatio, double widthRatio}) ratio =
            calculateBoxFitRatio(
              BoxFit.fill,
              const Size(0, 640),
              const Size(432, 256),
            );
        expect(ratio.widthRatio, 1.0);
        expect(ratio.heightRatio, 1.0);
      });

      test('Zero width/height in target size', () {
        final ({double heightRatio, double widthRatio}) ratio =
            calculateBoxFitRatio(
              BoxFit.fill,
              const Size(480, 640),
              const Size(0, 256),
            );
        expect(ratio.widthRatio, 1.0);
        expect(ratio.heightRatio, 1.0);
      });

      test('Equal sizes (no scaling)', () {
        final ({double heightRatio, double widthRatio}) ratio =
            calculateBoxFitRatio(
              BoxFit.fill,
              const Size(480, 640),
              const Size(480, 640),
            );
        expect(ratio.widthRatio, 1.0);
        expect(ratio.heightRatio, 1.0);
      });
    });
  });
}

class ScanWindowTestContext {
  ScanWindowTestContext({
    required this.textureSize,
    required this.widgetSize,
    required this.scanWindow,
  });

  final Size textureSize;
  final Size widgetSize;
  final Rect scanWindow;

  void testScanWindow(BoxFit fit, Rect expected) {
    final Rect actual = calculateScanWindowRelativeToTextureInPercentage(
      fit,
      scanWindow,
      textureSize: textureSize,
      widgetSize: widgetSize,
    );

    // Use closeTo because of possible floatingPoint errors
    expect(actual.left, closeTo(expected.left, 0.0001));
    expect(actual.top, closeTo(expected.top, 0.0001));
    expect(actual.right, closeTo(expected.right, 0.0001));
    expect(actual.bottom, closeTo(expected.bottom, 0.0001));
  }
}
