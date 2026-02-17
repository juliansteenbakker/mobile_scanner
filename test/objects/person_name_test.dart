import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/person_name.dart';

void main() {
  group('$PersonName tests', () {
    group('constructor', () {
      test('creates instance with default null values', () {
        const name = PersonName();

        expect(name.first, isNull);
        expect(name.middle, isNull);
        expect(name.last, isNull);
        expect(name.prefix, isNull);
        expect(name.suffix, isNull);
        expect(name.formattedName, isNull);
        expect(name.pronunciation, isNull);
      });

      test('creates instance with all values provided', () {
        const name = PersonName(
          first: 'John',
          middle: 'Michael',
          last: 'Doe',
          prefix: 'Dr.',
          suffix: 'Jr.',
          formattedName: 'Dr. John Michael Doe Jr.',
          pronunciation: 'jon mai-kuhl doh',
        );

        expect(name.first, 'John');
        expect(name.middle, 'Michael');
        expect(name.last, 'Doe');
        expect(name.prefix, 'Dr.');
        expect(name.suffix, 'Jr.');
        expect(name.formattedName, 'Dr. John Michael Doe Jr.');
        expect(name.pronunciation, 'jon mai-kuhl doh');
      });
    });

    group('fromNative', () {
      test('creates instance with empty map', () {
        final name = PersonName.fromNative(<Object?, Object?>{});

        expect(name.first, isNull);
        expect(name.middle, isNull);
        expect(name.last, isNull);
        expect(name.prefix, isNull);
        expect(name.suffix, isNull);
        expect(name.formattedName, isNull);
        expect(name.pronunciation, isNull);
      });

      test('creates instance with all values', () {
        final name = PersonName.fromNative(<Object?, Object?>{
          'first': 'John',
          'middle': 'Michael',
          'last': 'Doe',
          'prefix': 'Dr.',
          'suffix': 'Jr.',
          'formattedName': 'Dr. John Michael Doe Jr.',
          'pronunciation': 'jon mai-kuhl doh',
        });

        expect(name.first, 'John');
        expect(name.middle, 'Michael');
        expect(name.last, 'Doe');
        expect(name.prefix, 'Dr.');
        expect(name.suffix, 'Jr.');
        expect(name.formattedName, 'Dr. John Michael Doe Jr.');
        expect(name.pronunciation, 'jon mai-kuhl doh');
      });

      test('creates instance with null values', () {
        final name = PersonName.fromNative(<Object?, Object?>{
          'first': null,
          'middle': null,
          'last': null,
          'prefix': null,
          'suffix': null,
          'formattedName': null,
          'pronunciation': null,
        });

        expect(name.first, isNull);
        expect(name.middle, isNull);
        expect(name.last, isNull);
        expect(name.prefix, isNull);
        expect(name.suffix, isNull);
        expect(name.formattedName, isNull);
        expect(name.pronunciation, isNull);
      });

      test('creates instance with partial values', () {
        final name = PersonName.fromNative(<Object?, Object?>{
          'first': 'Jane',
          'last': 'Smith',
        });

        expect(name.first, 'Jane');
        expect(name.middle, isNull);
        expect(name.last, 'Smith');
        expect(name.prefix, isNull);
        expect(name.suffix, isNull);
        expect(name.formattedName, isNull);
        expect(name.pronunciation, isNull);
      });
    });
  });
}
