import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';

void main() {
  group('$BarcodeCapture tests', () {
    group('constructor', () {
      test('creates instance with default values', () {
        const capture = BarcodeCapture();

        expect(capture.barcodes, isEmpty);
        expect(capture.image, isNull);
        expect(capture.raw, isNull);
        expect(capture.size, Size.zero);
      });

      test('creates instance with all values provided', () {
        final image = Uint8List.fromList([1, 2, 3, 4]);
        const barcode = Barcode(rawValue: 'test');
        final raw = {'key': 'value'};

        final capture = BarcodeCapture(
          barcodes: const [barcode],
          image: image,
          raw: raw,
          size: const Size(1920, 1080),
        );

        expect(capture.barcodes, hasLength(1));
        expect(capture.barcodes.first.rawValue, 'test');
        expect(capture.image, image);
        expect(capture.raw, raw);
        expect(capture.size, const Size(1920, 1080));
      });

      test('creates instance with empty barcodes list', () {
        const capture = BarcodeCapture();

        expect(capture.barcodes, isEmpty);
      });

      test('creates instance with multiple barcodes', () {
        const capture = BarcodeCapture(
          barcodes: [
            Barcode(rawValue: 'barcode1'),
            Barcode(rawValue: 'barcode2'),
            Barcode(rawValue: 'barcode3'),
          ],
        );

        expect(capture.barcodes, hasLength(3));
        expect(capture.barcodes[0].rawValue, 'barcode1');
        expect(capture.barcodes[1].rawValue, 'barcode2');
        expect(capture.barcodes[2].rawValue, 'barcode3');
      });

      test('creates instance with image data', () {
        final image = Uint8List.fromList(List.generate(100, (i) => i));

        final capture = BarcodeCapture(image: image);

        expect(capture.image, isNotNull);
        expect(capture.image?.length, 100);
      });

      test('creates instance with various raw types', () {
        // Raw can be any object type
        final rawValues = <Object?>[
          'string raw',
          123,
          {'key': 'value'},
          [1, 2, 3],
          null,
        ];

        for (final raw in rawValues) {
          final capture = BarcodeCapture(raw: raw);

          expect(capture.raw, raw);
        }
      });
    });
  });
}
