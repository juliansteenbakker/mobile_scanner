import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/email_type.dart';
import 'package:mobile_scanner/src/objects/email.dart';

void main() {
  group('$Email tests', () {
    group('constructor', () {
      test('creates instance with default values', () {
        const email = Email();

        expect(email.address, isNull);
        expect(email.body, isNull);
        expect(email.subject, isNull);
        expect(email.type, EmailType.unknown);
      });

      test('creates instance with all values provided', () {
        const email = Email(
          address: 'test@example.com',
          body: 'Hello, this is a test email.',
          subject: 'Test Subject',
          type: EmailType.work,
        );

        expect(email.address, 'test@example.com');
        expect(email.body, 'Hello, this is a test email.');
        expect(email.subject, 'Test Subject');
        expect(email.type, EmailType.work);
      });
    });

    group('fromNative', () {
      test('creates instance with empty map', () {
        final email = Email.fromNative(<Object?, Object?>{});

        expect(email.address, isNull);
        expect(email.body, isNull);
        expect(email.subject, isNull);
        expect(email.type, EmailType.unknown);
      });

      test('creates instance with all values', () {
        final email = Email.fromNative(<Object?, Object?>{
          'address': 'test@example.com',
          'body': 'Hello, this is a test email.',
          'subject': 'Test Subject',
          'type': 1,
        });

        expect(email.address, 'test@example.com');
        expect(email.body, 'Hello, this is a test email.');
        expect(email.subject, 'Test Subject');
        expect(email.type, EmailType.work);
      });

      test('creates instance with null type defaults to unknown', () {
        final email = Email.fromNative(<Object?, Object?>{
          'address': 'test@example.com',
          'type': null,
        });

        expect(email.address, 'test@example.com');
        expect(email.type, EmailType.unknown);
      });

      test('creates instance with missing type defaults to unknown', () {
        final email = Email.fromNative(<Object?, Object?>{
          'address': 'test@example.com',
        });

        expect(email.address, 'test@example.com');
        expect(email.type, EmailType.unknown);
      });

      test('creates instance with all email types', () {
        for (final type in EmailType.values) {
          final email = Email.fromNative(<Object?, Object?>{
            'type': type.rawValue,
          });

          expect(
            email.type,
            type,
            reason: 'Type with raw value ${type.rawValue} should map to $type',
          );
        }
      });

      test('creates instance with null values', () {
        final email = Email.fromNative(<Object?, Object?>{
          'address': null,
          'body': null,
          'subject': null,
        });

        expect(email.address, isNull);
        expect(email.body, isNull);
        expect(email.subject, isNull);
      });

      test('handles out of range type value', () {
        final email = Email.fromNative(<Object?, Object?>{
          'type': 999,
        });

        expect(email.type, EmailType.unknown);
      });

      test('handles negative type value', () {
        final email = Email.fromNative(<Object?, Object?>{
          'type': -1,
        });

        expect(email.type, EmailType.unknown);
      });

      test('creates instance with special characters in email fields', () {
        final email = Email.fromNative(<Object?, Object?>{
          'address': 'user+tag@example.com',
          'subject': 'Re: Meeting & Follow-up',
          'body': 'Hello,\n\nThis is a test <message>.',
        });

        expect(email.address, 'user+tag@example.com');
        expect(email.subject, 'Re: Meeting & Follow-up');
        expect(email.body, 'Hello,\n\nThis is a test <message>.');
      });

      test('creates instance with Unicode in email fields', () {
        final email = Email.fromNative(<Object?, Object?>{
          'subject': '日本語の件名',
          'body': 'Cher ami, merci beaucoup!',
        });

        expect(email.subject, '日本語の件名');
        expect(email.body, 'Cher ami, merci beaucoup!');
      });

      test('creates instance with very long body', () {
        final longBody = 'A' * 10000;
        final email = Email.fromNative(<Object?, Object?>{
          'body': longBody,
        });

        expect(email.body?.length, 10000);
      });
    });
  });
}
