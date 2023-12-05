import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';

void main() {
  group('$BarcodeFormat tests', () {
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
        128: BarcodeFormat.itf,
        256: BarcodeFormat.qrCode,
        512: BarcodeFormat.upcA,
        1024: BarcodeFormat.upcE,
        2048: BarcodeFormat.pdf417,
        4096: BarcodeFormat.aztec,
      };

      for (final MapEntry<int, BarcodeFormat> entry in values.entries) {
        final BarcodeFormat result = BarcodeFormat.fromRawValue(entry.key);

        expect(result, entry.value);
      }
    });

    test('invalid raw value throws argument error', () {
      const int negative = -2;
      const int outOfRange = 4097;

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
        BarcodeFormat.itf: 128,
        BarcodeFormat.qrCode: 256,
        BarcodeFormat.upcA: 512,
        BarcodeFormat.upcE: 1024,
        BarcodeFormat.pdf417: 2048,
        BarcodeFormat.aztec: 4096,
      };

      for (final MapEntry<BarcodeFormat, int> entry in values.entries) {
        final int result = entry.key.rawValue;

        expect(result, entry.value);
      }
    });
  });
}
