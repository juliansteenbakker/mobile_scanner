import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/sms.dart';

void main() {
  group('$SMS tests', () {
    group('constructor', () {
      test('creates instance with required phone number', () {
        const sms = SMS(phoneNumber: '+1-555-123-4567');

        expect(sms.phoneNumber, '+1-555-123-4567');
        expect(sms.message, isNull);
      });

      test('creates instance with phone number and message', () {
        const sms = SMS(
          phoneNumber: '+1-555-123-4567',
          message: 'Hello, this is a test message.',
        );

        expect(sms.phoneNumber, '+1-555-123-4567');
        expect(sms.message, 'Hello, this is a test message.');
      });

      test('creates instance with empty phone number', () {
        const sms = SMS(phoneNumber: '');

        expect(sms.phoneNumber, '');
        expect(sms.message, isNull);
      });
    });

    group('fromNative', () {
      test('creates instance with empty map', () {
        final sms = SMS.fromNative(<Object?, Object?>{});

        expect(sms.phoneNumber, '');
        expect(sms.message, isNull);
      });

      test('creates instance with all values', () {
        final sms = SMS.fromNative(<Object?, Object?>{
          'phoneNumber': '+1-555-123-4567',
          'message': 'Hello, this is a test message.',
        });

        expect(sms.phoneNumber, '+1-555-123-4567');
        expect(sms.message, 'Hello, this is a test message.');
      });

      test(
        'creates instance with null phone number defaults to empty string',
        () {
          final sms = SMS.fromNative(<Object?, Object?>{
            'phoneNumber': null,
            'message': 'Hello',
          });

          expect(sms.phoneNumber, '');
          expect(sms.message, 'Hello');
        },
      );

      test('creates instance with null message', () {
        final sms = SMS.fromNative(<Object?, Object?>{
          'phoneNumber': '+1-555-123-4567',
          'message': null,
        });

        expect(sms.phoneNumber, '+1-555-123-4567');
        expect(sms.message, isNull);
      });

      test('creates instance with missing phone number defaults to empty', () {
        final sms = SMS.fromNative(<Object?, Object?>{
          'message': 'Hello',
        });

        expect(sms.phoneNumber, '');
        expect(sms.message, 'Hello');
      });
    });
  });
}
