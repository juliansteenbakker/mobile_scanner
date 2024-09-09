import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_type.dart';

void main() {
  group('$BarcodeType tests', () {
    test('can be created from raw value', () {
      const values = <int, BarcodeType>{
        0: BarcodeType.unknown,
        1: BarcodeType.contactInfo,
        2: BarcodeType.email,
        3: BarcodeType.isbn,
        4: BarcodeType.phone,
        5: BarcodeType.product,
        6: BarcodeType.sms,
        7: BarcodeType.text,
        8: BarcodeType.url,
        9: BarcodeType.wifi,
        10: BarcodeType.geo,
        11: BarcodeType.calendarEvent,
        12: BarcodeType.driverLicense,
      };

      for (final MapEntry<int, BarcodeType> entry in values.entries) {
        final BarcodeType result = BarcodeType.fromRawValue(entry.key);

        expect(result, entry.value);
      }
    });

    test('invalid raw value returns BarcodeType.unknown', () {
      const int negative = -1;
      const int outOfRange = 13;

      expect(BarcodeType.fromRawValue(negative), BarcodeType.unknown);
      expect(BarcodeType.fromRawValue(outOfRange), BarcodeType.unknown);
    });

    test('can be converted to raw value', () {
      const values = <BarcodeType, int>{
        BarcodeType.unknown: 0,
        BarcodeType.contactInfo: 1,
        BarcodeType.email: 2,
        BarcodeType.isbn: 3,
        BarcodeType.phone: 4,
        BarcodeType.product: 5,
        BarcodeType.sms: 6,
        BarcodeType.text: 7,
        BarcodeType.url: 8,
        BarcodeType.wifi: 9,
        BarcodeType.geo: 10,
        BarcodeType.calendarEvent: 11,
        BarcodeType.driverLicense: 12,
      };

      for (final MapEntry<BarcodeType, int> entry in values.entries) {
        final int result = entry.key.rawValue;

        expect(result, entry.value);
      }
    });
  });
}
