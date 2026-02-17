import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/address_type.dart';
import 'package:mobile_scanner/src/enums/email_type.dart';
import 'package:mobile_scanner/src/enums/phone_type.dart';
import 'package:mobile_scanner/src/objects/address.dart';
import 'package:mobile_scanner/src/objects/contact_info.dart';
import 'package:mobile_scanner/src/objects/email.dart';
import 'package:mobile_scanner/src/objects/person_name.dart';
import 'package:mobile_scanner/src/objects/phone.dart';

void main() {
  group('$ContactInfo tests', () {
    group('constructor', () {
      test('creates instance with default values', () {
        const contact = ContactInfo();

        expect(contact.addresses, isEmpty);
        expect(contact.emails, isEmpty);
        expect(contact.name, isNull);
        expect(contact.organization, isNull);
        expect(contact.phones, isEmpty);
        expect(contact.title, isNull);
        expect(contact.urls, isEmpty);
      });

      test('creates instance with all values provided', () {
        const name = PersonName(first: 'John', last: 'Doe');
        const address = Address(
          addressLines: ['123 Main St'],
          type: AddressType.home,
        );
        const email = Email(
          address: 'john@example.com',
          type: EmailType.home,
        );
        const phone = Phone(number: '+1-555-123-4567', type: PhoneType.mobile);

        const contact = ContactInfo(
          addresses: [address],
          emails: [email],
          name: name,
          organization: 'Acme Inc.',
          phones: [phone],
          title: 'Software Engineer',
          urls: ['https://example.com'],
        );

        expect(contact.addresses, hasLength(1));
        expect(contact.emails, hasLength(1));
        expect(contact.name?.first, 'John');
        expect(contact.organization, 'Acme Inc.');
        expect(contact.phones, hasLength(1));
        expect(contact.title, 'Software Engineer');
        expect(contact.urls, ['https://example.com']);
      });
    });

    group('fromNative', () {
      test('creates instance with empty map', () {
        final contact = ContactInfo.fromNative(<Object?, Object?>{});

        expect(contact.addresses, isEmpty);
        expect(contact.emails, isEmpty);
        expect(contact.name, isNull);
        expect(contact.organization, isNull);
        expect(contact.phones, isEmpty);
        expect(contact.title, isNull);
        expect(contact.urls, isEmpty);
      });

      test('creates instance with all values', () {
        final contact = ContactInfo.fromNative(<Object?, Object?>{
          'addresses': <Object?>[
            <Object?, Object?>{
              'addressLines': <Object?>['123 Main St', 'Apt 4'],
              'type': 2,
            },
          ],
          'emails': <Object?>[
            <Object?, Object?>{
              'address': 'john@example.com',
              'type': 2,
            },
          ],
          'name': <Object?, Object?>{
            'first': 'John',
            'last': 'Doe',
          },
          'organization': 'Acme Inc.',
          'phones': <Object?>[
            <Object?, Object?>{
              'number': '+1-555-123-4567',
              'type': 4,
            },
          ],
          'title': 'Software Engineer',
          'urls': <Object?>['https://example.com', 'https://linkedin.com'],
        });

        expect(contact.addresses, hasLength(1));
        expect(contact.addresses.first.addressLines, ['123 Main St', 'Apt 4']);
        expect(contact.addresses.first.type, AddressType.home);

        expect(contact.emails, hasLength(1));
        expect(contact.emails.first.address, 'john@example.com');
        expect(contact.emails.first.type, EmailType.home);

        expect(contact.name?.first, 'John');
        expect(contact.name?.last, 'Doe');

        expect(contact.organization, 'Acme Inc.');

        expect(contact.phones, hasLength(1));
        expect(contact.phones.first.number, '+1-555-123-4567');
        expect(contact.phones.first.type, PhoneType.mobile);

        expect(contact.title, 'Software Engineer');
        expect(contact.urls, ['https://example.com', 'https://linkedin.com']);
      });

      test('creates instance with null addresses', () {
        final contact = ContactInfo.fromNative(<Object?, Object?>{
          'addresses': null,
        });

        expect(contact.addresses, isEmpty);
      });

      test('creates instance with null emails', () {
        final contact = ContactInfo.fromNative(<Object?, Object?>{
          'emails': null,
        });

        expect(contact.emails, isEmpty);
      });

      test('creates instance with null phones', () {
        final contact = ContactInfo.fromNative(<Object?, Object?>{
          'phones': null,
        });

        expect(contact.phones, isEmpty);
      });

      test('creates instance with null urls', () {
        final contact = ContactInfo.fromNative(<Object?, Object?>{
          'urls': null,
        });

        expect(contact.urls, isEmpty);
      });

      test('creates instance with null name', () {
        final contact = ContactInfo.fromNative(<Object?, Object?>{
          'name': null,
        });

        expect(contact.name, isNull);
      });

      test('creates instance with multiple addresses', () {
        final contact = ContactInfo.fromNative(<Object?, Object?>{
          'addresses': <Object?>[
            <Object?, Object?>{
              'addressLines': <Object?>['Home address'],
              'type': 2,
            },
            <Object?, Object?>{
              'addressLines': <Object?>['Work address'],
              'type': 1,
            },
          ],
        });

        expect(contact.addresses, hasLength(2));
        expect(contact.addresses[0].type, AddressType.home);
        expect(contact.addresses[1].type, AddressType.work);
      });

      test('creates instance with multiple emails', () {
        final contact = ContactInfo.fromNative(<Object?, Object?>{
          'emails': <Object?>[
            <Object?, Object?>{
              'address': 'home@example.com',
              'type': 2,
            },
            <Object?, Object?>{
              'address': 'work@example.com',
              'type': 1,
            },
          ],
        });

        expect(contact.emails, hasLength(2));
        expect(contact.emails[0].type, EmailType.home);
        expect(contact.emails[1].type, EmailType.work);
      });

      test('creates instance with multiple phones', () {
        final contact = ContactInfo.fromNative(<Object?, Object?>{
          'phones': <Object?>[
            <Object?, Object?>{
              'number': '+1-555-111-1111',
              'type': 2,
            },
            <Object?, Object?>{
              'number': '+1-555-222-2222',
              'type': 4,
            },
          ],
        });

        expect(contact.phones, hasLength(2));
        expect(contact.phones[0].type, PhoneType.home);
        expect(contact.phones[1].type, PhoneType.mobile);
      });
    });
  });
}
