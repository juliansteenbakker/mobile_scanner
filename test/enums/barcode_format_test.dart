import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';

void main() {
  group('BarcodeFormat tests', () {
    test('can be created from raw value', () {
      const values = <int, BarcodeFormat>{
        -1: BarcodeFormat.unknown,
        0: BarcodeFormat.all,
        1: BarcodeFormat.code128,
        2: BarcodeFormat.code39,
        4: BarcodeFormat.code93,
        8: BarcodeFormat.codabar,
        16: BarcodeFormat.dataMatrix,
        32: BarcodeFormat.ean13,
        64: BarcodeFormat.ean8,
        126: BarcodeFormat.itf2of5,
        127: BarcodeFormat.itf2of5WithChecksum,
        128: BarcodeFormat.itf14,
        256: BarcodeFormat.qrCode,
        512: BarcodeFormat.upcA,
        1024: BarcodeFormat.upcE,
        2048: BarcodeFormat.pdf417,
        4096: BarcodeFormat.aztec,
        8192: BarcodeFormat.maxiCode,
        16384: BarcodeFormat.microQrCode,
        32768: BarcodeFormat.dataBar,
        65536: BarcodeFormat.dataBarExpanded,
        131072: BarcodeFormat.dataBarLimited,
      };

      for (final entry in values.entries) {
        final result = BarcodeFormat.fromRawValue(entry.key);

        expect(result, entry.value);
      }

      final expectedRawValues =
          BarcodeFormat.values.map((e) => e.rawValue).toSet();
      final actualRawValues = values.keys.toSet();

      // Deprecated formats are collapsed into their replacements,
      // so compare the values using a Set.
      expect(
        actualRawValues.length,
        expectedRawValues.length,
        reason: 'All BarcodeFormats should be tested.',
      );
    });

    test('invalid raw value throws argument error', () {
      const negative = -2;
      const outOfRange = 131073;

      expect(() => BarcodeFormat.fromRawValue(negative), throwsArgumentError);
      expect(() => BarcodeFormat.fromRawValue(outOfRange), throwsArgumentError);
    });

    test('can be converted to raw value', () {
      const values = <BarcodeFormat, int>{
        BarcodeFormat.unknown: -1,
        BarcodeFormat.all: 0,
        BarcodeFormat.code128: 1,
        BarcodeFormat.code39: 2,
        BarcodeFormat.code93: 4,
        BarcodeFormat.codabar: 8,
        BarcodeFormat.dataMatrix: 16,
        BarcodeFormat.ean13: 32,
        BarcodeFormat.ean8: 64,
        BarcodeFormat.itf2of5: 126,
        BarcodeFormat.itf2of5WithChecksum: 127,
        BarcodeFormat.itf: 128,
        BarcodeFormat.itf14: 128,
        BarcodeFormat.qrCode: 256,
        BarcodeFormat.upcA: 512,
        BarcodeFormat.upcE: 1024,
        BarcodeFormat.pdf417: 2048,
        BarcodeFormat.aztec: 4096,
        BarcodeFormat.maxiCode: 8192,
        BarcodeFormat.microQrCode: 16384,
        BarcodeFormat.dataBar: 32768,
        BarcodeFormat.dataBarExpanded: 65536,
        BarcodeFormat.dataBarLimited: 131072,
      };

      for (final entry in values.entries) {
        final result = entry.key.rawValue;

        expect(result, entry.value);
      }

      expect(
        values.entries.length,
        BarcodeFormat.values.length,
        reason: 'All BarcodeFormats should be tested.',
      );
    });
  });
}
