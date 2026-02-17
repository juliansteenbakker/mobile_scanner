import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/address_type.dart';
import 'package:mobile_scanner/src/objects/address.dart';

void main() {
  group('$Address tests', () {
    group('constructor', () {
      test('creates instance with default values', () {
        const address = Address();

        expect(address.addressLines, isEmpty);
        expect(address.type, AddressType.unknown);
      });

      test('creates instance with provided values', () {
        const address = Address(
          addressLines: ['123 Main St', 'Apt 4'],
          type: AddressType.home,
        );

        expect(address.addressLines, ['123 Main St', 'Apt 4']);
        expect(address.type, AddressType.home);
      });
    });

    group('fromNative', () {
      test('creates instance with null addressLines', () {
        final address = Address.fromNative(<Object?, Object?>{
          'addressLines': null,
          'type': 2,
        });

        expect(address.addressLines, isEmpty);
        expect(address.type, AddressType.home);
      });

      test('creates instance with empty addressLines', () {
        final address = Address.fromNative(<Object?, Object?>{
          'addressLines': <Object?>[],
          'type': 1,
        });

        expect(address.addressLines, isEmpty);
        expect(address.type, AddressType.work);
      });

      test('creates instance with addressLines', () {
        final address = Address.fromNative(<Object?, Object?>{
          'addressLines': <Object?>['123 Main St', 'Suite 100'],
          'type': 2,
        });

        expect(address.addressLines, ['123 Main St', 'Suite 100']);
        expect(address.type, AddressType.home);
      });

      test('creates instance with null type defaults to unknown', () {
        final address = Address.fromNative(<Object?, Object?>{
          'addressLines': <Object?>['123 Main St'],
          'type': null,
        });

        expect(address.addressLines, ['123 Main St']);
        expect(address.type, AddressType.unknown);
      });

      test('creates instance with missing type defaults to unknown', () {
        final address = Address.fromNative(<Object?, Object?>{
          'addressLines': <Object?>['123 Main St'],
        });

        expect(address.addressLines, ['123 Main St']);
        expect(address.type, AddressType.unknown);
      });

      test('creates instance with all address types', () {
        for (final type in AddressType.values) {
          final address = Address.fromNative(<Object?, Object?>{
            'type': type.rawValue,
          });

          expect(
            address.type,
            type,
            reason: 'Type with raw value ${type.rawValue} should map to $type',
          );
        }
      });

      test('handles out of range type value', () {
        final address = Address.fromNative(<Object?, Object?>{
          'type': 999,
        });

        expect(address.type, AddressType.unknown);
      });

      test('handles negative type value', () {
        final address = Address.fromNative(<Object?, Object?>{
          'type': -1,
        });

        expect(address.type, AddressType.unknown);
      });

      test('creates instance with special characters in address lines', () {
        final address = Address.fromNative(<Object?, Object?>{
          'addressLines': <Object?>[
            '123 Main St, Apt #4',
            'City & State',
            'Country: USA',
          ],
        });

        expect(address.addressLines, [
          '123 Main St, Apt #4',
          'City & State',
          'Country: USA',
        ]);
      });

      test('creates instance with Unicode characters in address lines', () {
        final address = Address.fromNative(<Object?, Object?>{
          'addressLines': <Object?>[
            '東京都渋谷区',
            'Müller Straße 42',
            'Café de la Paix',
          ],
        });

        expect(address.addressLines, [
          '東京都渋谷区',
          'Müller Straße 42',
          'Café de la Paix',
        ]);
      });

      test('creates instance with very long address line', () {
        final longAddress = 'A' * 1000;
        final address = Address.fromNative(<Object?, Object?>{
          'addressLines': <Object?>[longAddress],
        });

        expect(address.addressLines.first.length, 1000);
      });
    });
  });
}
