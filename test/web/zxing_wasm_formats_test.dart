import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/web/zxing_wasm/zxing_wasm_formats.dart';

void main() {
  group('zxing-wasm format string to BarcodeFormat', () {
    test('maps all canonical format strings', () {
      expect('Aztec'.toBarcodeFormat, BarcodeFormat.aztec);
      expect('Codabar'.toBarcodeFormat, BarcodeFormat.codabar);
      expect('Code39'.toBarcodeFormat, BarcodeFormat.code39);
      expect('Code93'.toBarcodeFormat, BarcodeFormat.code93);
      expect('Code128'.toBarcodeFormat, BarcodeFormat.code128);
      expect('DataMatrix'.toBarcodeFormat, BarcodeFormat.dataMatrix);
      expect('EAN8'.toBarcodeFormat, BarcodeFormat.ean8);
      expect('EAN13'.toBarcodeFormat, BarcodeFormat.ean13);
      expect('ITF'.toBarcodeFormat, BarcodeFormat.itf);
      expect('ITF14'.toBarcodeFormat, BarcodeFormat.itf14);
      expect('PDF417'.toBarcodeFormat, BarcodeFormat.pdf417);
      expect('QRCode'.toBarcodeFormat, BarcodeFormat.qrCode);
      expect('UPCA'.toBarcodeFormat, BarcodeFormat.upcA);
      expect('UPCE'.toBarcodeFormat, BarcodeFormat.upcE);
    });

    test('maps sub-variant format strings to their base format', () {
      expect('AztecCode'.toBarcodeFormat, BarcodeFormat.aztec);
      expect('AztecRune'.toBarcodeFormat, BarcodeFormat.aztec);
      expect('Code39Std'.toBarcodeFormat, BarcodeFormat.code39);
      expect('Code39Ext'.toBarcodeFormat, BarcodeFormat.code39);
      expect('Code32'.toBarcodeFormat, BarcodeFormat.code39);
      expect('PZN'.toBarcodeFormat, BarcodeFormat.code39);
      expect('ISBN'.toBarcodeFormat, BarcodeFormat.ean13);
      expect('CompactPDF417'.toBarcodeFormat, BarcodeFormat.pdf417);
      expect('MicroPDF417'.toBarcodeFormat, BarcodeFormat.pdf417);
      expect('QRCodeModel1'.toBarcodeFormat, BarcodeFormat.qrCode);
      expect('QRCodeModel2'.toBarcodeFormat, BarcodeFormat.qrCode);
    });

    test('maps legacy hyphenated (2.x) format strings', () {
      expect('EAN-8'.toBarcodeFormat, BarcodeFormat.ean8);
      expect('EAN-13'.toBarcodeFormat, BarcodeFormat.ean13);
      expect('UPC-A'.toBarcodeFormat, BarcodeFormat.upcA);
      expect('UPC-E'.toBarcodeFormat, BarcodeFormat.upcE);
    });

    test('maps unrecognized strings to unknown', () {
      expect('None'.toBarcodeFormat, BarcodeFormat.unknown);
      expect(''.toBarcodeFormat, BarcodeFormat.unknown);
      expect('qrcode'.toBarcodeFormat, BarcodeFormat.unknown);
      expect('MaxiCode'.toBarcodeFormat, BarcodeFormat.unknown);
    });
  });

  group('BarcodeFormat to zxing-wasm format string', () {
    test('maps the ITF variants', () {
      expect(BarcodeFormat.itf.toZXingWasmString, 'ITF');
      expect(BarcodeFormat.itf14.toZXingWasmString, 'ITF14');
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
