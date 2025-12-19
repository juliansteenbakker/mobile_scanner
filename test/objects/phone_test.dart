import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/phone_type.dart';
import 'package:mobile_scanner/src/objects/phone.dart';

void main() {
  group('$Phone tests', () {
    group('constructor', () {
      test('creates instance with default values', () {
        const phone = Phone();

        expect(phone.number, isNull);
        expect(phone.type, PhoneType.unknown);
      });

      test('creates instance with all values provided', () {
        const phone = Phone(number: '+1-555-123-4567', type: PhoneType.mobile);

        expect(phone.number, '+1-555-123-4567');
        expect(phone.type, PhoneType.mobile);
      });
    });

    group('fromNative', () {
      test('creates instance with empty map', () {
        final phone = Phone.fromNative(<Object?, Object?>{});

        expect(phone.number, isNull);
        expect(phone.type, PhoneType.unknown);
      });

      test('creates instance with all values', () {
        final phone = Phone.fromNative(<Object?, Object?>{
          'number': '+1-555-123-4567',
          'type': 4,
        });

        expect(phone.number, '+1-555-123-4567');
        expect(phone.type, PhoneType.mobile);
      });

      test('creates instance with null type defaults to unknown', () {
        final phone = Phone.fromNative(<Object?, Object?>{
          'number': '+1-555-123-4567',
          'type': null,
        });

        expect(phone.number, '+1-555-123-4567');
        expect(phone.type, PhoneType.unknown);
      });

      test('creates instance with missing type defaults to unknown', () {
        final phone = Phone.fromNative(<Object?, Object?>{
          'number': '+1-555-123-4567',
        });

        expect(phone.number, '+1-555-123-4567');
        expect(phone.type, PhoneType.unknown);
      });

      test('creates instance with all phone types', () {
        for (final type in PhoneType.values) {
          final phone = Phone.fromNative(<Object?, Object?>{
            'type': type.rawValue,
          });

          expect(
            phone.type,
            type,
            reason: 'Type with raw value ${type.rawValue} should map to $type',
          );
        }
      });

      test('creates instance with null number', () {
        final phone = Phone.fromNative(<Object?, Object?>{
          'number': null,
          'type': 2,
        });

        expect(phone.number, isNull);
        expect(phone.type, PhoneType.home);
      });
    });
  });
}
