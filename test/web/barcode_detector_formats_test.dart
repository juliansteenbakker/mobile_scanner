import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/web/barcode_detector/barcode_detector_formats.dart';

void main() {
  group('BarcodeDetector format string to BarcodeFormat', () {
    test('maps all known format strings', () {
      expect('aztec'.toBarcodeFormat, BarcodeFormat.aztec);
      expect('codabar'.toBarcodeFormat, BarcodeFormat.codabar);
      expect('code_39'.toBarcodeFormat, BarcodeFormat.code39);
      expect('code_93'.toBarcodeFormat, BarcodeFormat.code93);
      expect('code_128'.toBarcodeFormat, BarcodeFormat.code128);
      expect('data_matrix'.toBarcodeFormat, BarcodeFormat.dataMatrix);
      expect('ean_8'.toBarcodeFormat, BarcodeFormat.ean8);
      expect('ean_13'.toBarcodeFormat, BarcodeFormat.ean13);
      expect('itf'.toBarcodeFormat, BarcodeFormat.itf);
      expect('pdf417'.toBarcodeFormat, BarcodeFormat.pdf417);
      expect('qr_code'.toBarcodeFormat, BarcodeFormat.qrCode);
      expect('upc_a'.toBarcodeFormat, BarcodeFormat.upcA);
      expect('upc_e'.toBarcodeFormat, BarcodeFormat.upcE);
    });

    test('maps unrecognized strings to unknown', () {
      expect('unknown'.toBarcodeFormat, BarcodeFormat.unknown);
      expect(''.toBarcodeFormat, BarcodeFormat.unknown);
      expect('QR_CODE'.toBarcodeFormat, BarcodeFormat.unknown);
    });
  });

  group('BarcodeFormat to BarcodeDetector format string', () {
    test('maps the ITF variants to itf', () {
      expect(BarcodeFormat.itf.toBarcodeDetectorString, 'itf');
      expect(BarcodeFormat.itf14.toBarcodeDetectorString, 'itf');
      expect(BarcodeFormat.itf2of5.toBarcodeDetectorString, 'itf');
      expect(BarcodeFormat.itf2of5WithChecksum.toBarcodeDetectorString, 'itf');
    });

    test('maps all and unknown to null', () {
      expect(BarcodeFormat.all.toBarcodeDetectorString, null);
      expect(BarcodeFormat.unknown.toBarcodeDetectorString, null);
    });

    test('every mapped format string round-trips to a BarcodeFormat', () {
      for (final format in BarcodeFormat.values) {
        final str = format.toBarcodeDetectorString;

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
