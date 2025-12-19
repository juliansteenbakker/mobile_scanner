import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/barcode_type.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';

void main() {
  group('$Barcode tests', () {
    group('constructor', () {
      test('creates instance with default values', () {
        const barcode = Barcode();

        expect(barcode.calendarEvent, isNull);
        expect(barcode.contactInfo, isNull);
        expect(barcode.corners, isEmpty);
        expect(barcode.displayValue, isNull);
        expect(barcode.driverLicense, isNull);
        expect(barcode.email, isNull);
        expect(barcode.format, BarcodeFormat.unknown);
        expect(barcode.geoPoint, isNull);
        expect(barcode.phone, isNull);
        expect(barcode.rawBytes, isNull);
        expect(barcode.rawValue, isNull);
        expect(barcode.size, Size.zero);
        expect(barcode.sms, isNull);
        expect(barcode.type, BarcodeType.unknown);
        expect(barcode.url, isNull);
        expect(barcode.wifi, isNull);
      });

      test('creates instance with rawValue and displayValue', () {
        const barcode = Barcode(
          rawValue: 'https://example.com',
          displayValue: 'example.com',
          format: BarcodeFormat.qrCode,
          type: BarcodeType.url,
        );

        expect(barcode.rawValue, 'https://example.com');
        expect(barcode.displayValue, 'example.com');
        expect(barcode.format, BarcodeFormat.qrCode);
        expect(barcode.type, BarcodeType.url);
      });
    });

    group('fromNative', () {
      test('creates instance with empty map', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{});

        expect(barcode.calendarEvent, isNull);
        expect(barcode.contactInfo, isNull);
        expect(barcode.corners, isEmpty);
        expect(barcode.displayValue, isNull);
        expect(barcode.driverLicense, isNull);
        expect(barcode.email, isNull);
        expect(barcode.format, BarcodeFormat.unknown);
        expect(barcode.geoPoint, isNull);
        expect(barcode.phone, isNull);
        expect(barcode.rawBytes, isNull);
        expect(barcode.rawValue, isNull);
        expect(barcode.size, Size.zero);
        expect(barcode.sms, isNull);
        expect(barcode.type, BarcodeType.unknown);
        expect(barcode.url, isNull);
        expect(barcode.wifi, isNull);
      });

      test('creates instance with basic values', () {
        final rawBytes = Uint8List.fromList([1, 2, 3]);
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'rawValue': 'https://example.com',
          'displayValue': 'example.com',
          'rawBytes': rawBytes,
          'format': BarcodeFormat.qrCode.rawValue,
          'type': BarcodeType.url.rawValue,
        });

        expect(barcode.rawValue, 'https://example.com');
        expect(barcode.displayValue, 'example.com');
        expect(barcode.rawBytes, rawBytes);
        expect(barcode.format, BarcodeFormat.qrCode);
        expect(barcode.type, BarcodeType.url);
      });

      test('creates instance with size', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'size': <Object?, Object?>{
            'width': 100.0,
            'height': 50.0,
          },
        });

        expect(barcode.size, const Size(100, 50));
      });

      test('creates instance with null size values', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'size': <Object?, Object?>{
            'width': null,
            'height': 50.0,
          },
        });

        expect(barcode.size, Size.zero);
      });

      test('creates instance with corners', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'corners': <Object?>[
            <Object?, Object?>{'x': 10.0, 'y': 10.0},
            <Object?, Object?>{'x': 90.0, 'y': 10.0},
            <Object?, Object?>{'x': 90.0, 'y': 90.0},
            <Object?, Object?>{'x': 10.0, 'y': 90.0},
          ],
        });

        expect(barcode.corners, hasLength(4));
        expect(barcode.corners[0], const Offset(10, 10));
        expect(barcode.corners[1], const Offset(90, 10));
        expect(barcode.corners[2], const Offset(90, 90));
        expect(barcode.corners[3], const Offset(10, 90));
      });

      test('creates instance with null corners', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'corners': null,
        });

        expect(barcode.corners, isEmpty);
      });

      test('creates instance with calendarEvent', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'calendarEvent': <Object?, Object?>{
            'summary': 'Meeting',
            'description': 'Team standup',
            'start': '2024-01-15T10:00:00',
            'end': '2024-01-15T11:00:00',
          },
        });

        expect(barcode.calendarEvent, isNotNull);
        expect(barcode.calendarEvent!.summary, 'Meeting');
        expect(barcode.calendarEvent!.description, 'Team standup');
      });

      test('creates instance with contactInfo', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'contactInfo': <Object?, Object?>{
            'name': <Object?, Object?>{
              'first': 'John',
              'last': 'Doe',
            },
            'organization': 'Acme Inc.',
          },
        });

        expect(barcode.contactInfo, isNotNull);
        expect(barcode.contactInfo!.name?.first, 'John');
        expect(barcode.contactInfo!.organization, 'Acme Inc.');
      });

      test('creates instance with driverLicense', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'driverLicense': <Object?, Object?>{
            'firstName': 'John',
            'lastName': 'Doe',
            'licenseNumber': 'D1234567',
          },
        });

        expect(barcode.driverLicense, isNotNull);
        expect(barcode.driverLicense!.firstName, 'John');
        expect(barcode.driverLicense!.licenseNumber, 'D1234567');
      });

      test('creates instance with email', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'email': <Object?, Object?>{
            'address': 'test@example.com',
            'subject': 'Hello',
            'body': 'Message body',
          },
        });

        expect(barcode.email, isNotNull);
        expect(barcode.email!.address, 'test@example.com');
        expect(barcode.email!.subject, 'Hello');
      });

      test('creates instance with geoPoint', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'geoPoint': <Object?, Object?>{
            'latitude': 37.7749,
            'longitude': -122.4194,
          },
        });

        expect(barcode.geoPoint, isNotNull);
        expect(barcode.geoPoint!.latitude, 37.7749);
        expect(barcode.geoPoint!.longitude, -122.4194);
      });

      test('creates instance with phone', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'phone': <Object?, Object?>{
            'number': '+1-555-123-4567',
            'type': 2,
          },
        });

        expect(barcode.phone, isNotNull);
        expect(barcode.phone!.number, '+1-555-123-4567');
      });

      test('creates instance with sms', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'sms': <Object?, Object?>{
            'phoneNumber': '+1-555-123-4567',
            'message': 'Hello',
          },
        });

        expect(barcode.sms, isNotNull);
        expect(barcode.sms!.phoneNumber, '+1-555-123-4567');
        expect(barcode.sms!.message, 'Hello');
      });

      test('creates instance with url', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'url': <Object?, Object?>{
            'url': 'https://example.com',
            'title': 'Example',
          },
        });

        expect(barcode.url, isNotNull);
        expect(barcode.url!.url, 'https://example.com');
        expect(barcode.url!.title, 'Example');
      });

      test('creates instance with wifi', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'wifi': <Object?, Object?>{
            'ssid': 'MyNetwork',
            'password': 'secret',
            'encryptionType': 2,
          },
        });

        expect(barcode.wifi, isNotNull);
        expect(barcode.wifi!.ssid, 'MyNetwork');
        expect(barcode.wifi!.password, 'secret');
      });

      test('creates instance with null format defaults to unknown', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'format': null,
        });

        expect(barcode.format, BarcodeFormat.unknown);
      });

      test('creates instance with null type defaults to unknown', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'type': null,
        });

        expect(barcode.type, BarcodeType.unknown);
      });

      test('creates instance with all barcode formats', () {
        for (final format in BarcodeFormat.values) {
          final barcode = Barcode.fromNative(<Object?, Object?>{
            'format': format.rawValue,
          });

          expect(
            barcode.format,
            format,
            reason:
                'Format with raw value ${format.rawValue} should map to '
                '$format',
          );
        }
      });

      test('creates instance with all barcode types', () {
        for (final type in BarcodeType.values) {
          final barcode = Barcode.fromNative(<Object?, Object?>{
            'type': type.rawValue,
          });

          expect(
            barcode.type,
            type,
            reason:
                'Type with raw value ${type.rawValue} should map to $type',
          );
        }
      });
    });

    group('scaleCorners', () {
      test('returns empty list if barcode has no size or corners', () {
        const barcode = Barcode();

        expect(barcode.scaleCorners(const Size(100, 100)), isEmpty);
      });

      test('returns empty list if barcode has no corners', () {
        const barcode = Barcode(size: Size(200, 200));

        expect(barcode.scaleCorners(const Size(100, 100)), isEmpty);
      });

      test('returns zeroed corners if barcode has corners but no size', () {
        const barcode = Barcode(
          corners: [Offset.zero, Offset.zero, Offset.zero, Offset.zero],
        );

        expect(barcode.scaleCorners(const Size(100, 100)), [
          Offset.zero,
          Offset.zero,
          Offset.zero,
          Offset.zero,
        ]);
      });

      test('returns zeroed corners if target size is empty', () {
        const barcode = Barcode(
          size: Size(200, 200),
          corners: [
            Offset(50, 50),
            Offset(150, 50),
            Offset(150, 150),
            Offset(50, 150),
          ],
        );

        expect(barcode.scaleCorners(Size.zero), [
          Offset.zero,
          Offset.zero,
          Offset.zero,
          Offset.zero,
        ]);
      });

      test('returns scaled corners', () {
        const barcode = Barcode(
          size: Size(100, 100),
          corners: [
            Offset(25, 25),
            Offset(75, 25),
            Offset(75, 75),
            Offset(25, 75),
          ],
        );

        expect(barcode.scaleCorners(const Size(200, 200)), const [
          Offset(50, 50),
          Offset(150, 50),
          Offset(150, 150),
          Offset(50, 150),
        ]);
      });
    });
  });
}
