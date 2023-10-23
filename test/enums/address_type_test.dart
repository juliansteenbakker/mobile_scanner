import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/address_type.dart';

void main() {
  group('$AddressType tests', () {
    test('can be created from raw value', () {
      const values = <int, AddressType>{
        0: AddressType.unknown,
        1: AddressType.work,
        2: AddressType.home,
      };

      for (final MapEntry<int, AddressType> entry in values.entries) {
        final AddressType result = AddressType.fromRawValue(entry.key);

        expect(result, entry.value);
      }
    });

    test('invalid raw value throws argument error', () {
      const int negative = -1;
      const int outOfRange = 3;

      expect(() => AddressType.fromRawValue(negative), throwsArgumentError);
      expect(() => AddressType.fromRawValue(outOfRange), throwsArgumentError);
    });

    test('can be converted to raw value', () {
      const values = <AddressType, int>{
        AddressType.unknown: 0,
        AddressType.work: 1,
        AddressType.home: 2,
      };

      for (final MapEntry<AddressType, int> entry in values.entries) {
        final int result = entry.key.rawValue;

        expect(result, entry.value);
      }
    });
  });
}
