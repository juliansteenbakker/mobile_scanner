import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/web/zxing_wasm/zxing_wasm_formats.dart';

void main() {
  group('zxing-wasm format string to BarcodeFormat', () {
    test('maps all known format strings', () {
      expect('Aztec'.toBarcodeFormat, BarcodeFormat.aztec);
      expect('Codabar'.toBarcodeFormat, BarcodeFormat.codabar);
      expect('Code39'.toBarcodeFormat, BarcodeFormat.code39);
      expect('Code93'.toBarcodeFormat, BarcodeFormat.code93);
      expect('Code128'.toBarcodeFormat, BarcodeFormat.code128);
      expect('DataMatrix'.toBarcodeFormat, BarcodeFormat.dataMatrix);
      expect('EAN-8'.toBarcodeFormat, BarcodeFormat.ean8);
      expect('EAN-13'.toBarcodeFormat, BarcodeFormat.ean13);
      expect('ITF'.toBarcodeFormat, BarcodeFormat.itf);
      expect('PDF417'.toBarcodeFormat, BarcodeFormat.pdf417);
      expect('QRCode'.toBarcodeFormat, BarcodeFormat.qrCode);
      expect('UPC-A'.toBarcodeFormat, BarcodeFormat.upcA);
      expect('UPC-E'.toBarcodeFormat, BarcodeFormat.upcE);
    });

    test('maps unrecognized strings to unknown', () {
      expect('None'.toBarcodeFormat, BarcodeFormat.unknown);
      expect(''.toBarcodeFormat, BarcodeFormat.unknown);
      expect('qrcode'.toBarcodeFormat, BarcodeFormat.unknown);
    });
  });

  group('BarcodeFormat to zxing-wasm format string', () {
    test('maps the ITF variants to ITF', () {
      expect(BarcodeFormat.itf.toZXingWasmString, 'ITF');
      expect(BarcodeFormat.itf14.toZXingWasmString, 'ITF');
      expect(BarcodeFormat.itf2of5.toZXingWasmString, 'ITF');
      expect(BarcodeFormat.itf2of5WithChecksum.toZXingWasmString, 'ITF');
    });

    test('maps all and unknown to null', () {
      expect(BarcodeFormat.all.toZXingWasmString, null);
      expect(BarcodeFormat.unknown.toZXingWasmString, null);
    });

    test('every mapped format string round-trips to a BarcodeFormat', () {
      for (final format in BarcodeFormat.values) {
        final str = format.toZXingWasmString;

        if (str == null) {
          continue;
        }

        expect(
          str.toBarcodeFormat,
          isNot(BarcodeFormat.unknown),
          reason: '$format maps to "$str" which should map back',
        );
      }
    });
  });
}
