import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/barcode_type.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/objects/calendar_event.dart';
import 'package:mobile_scanner/src/objects/contact_info.dart';
import 'package:mobile_scanner/src/objects/driver_license.dart';
import 'package:mobile_scanner/src/objects/email.dart';
import 'package:mobile_scanner/src/objects/geo_point.dart';
import 'package:mobile_scanner/src/objects/phone.dart';
import 'package:mobile_scanner/src/objects/sms.dart';
import 'package:mobile_scanner/src/objects/url_bookmark.dart';
import 'package:mobile_scanner/src/objects/wifi.dart';

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

      test('creates instance with all values provided', () {
        const calendarEvent = CalendarEvent(summary: 'Meeting');
        const contactInfo = ContactInfo();
        const corners = [
          Offset.zero,
          Offset(100, 0),
          Offset(100, 100),
          Offset(0, 100),
        ];
        const driverLicense = DriverLicense(firstName: 'John');
        const email = Email(address: 'test@example.com');
        const geoPoint = GeoPoint(latitude: 37.7749, longitude: -122.4194);
        const phone = Phone(number: '+1234567890');
        final rawBytes = Uint8List.fromList([1, 2, 3, 4]);
        const sms = SMS(phoneNumber: '+1234567890', message: 'Hello');
        const url = UrlBookmark(url: 'https://example.com');
        const wifi = WiFi(ssid: 'TestNetwork');

        final barcode = Barcode(
          calendarEvent: calendarEvent,
          contactInfo: contactInfo,
          corners: corners,
          displayValue: 'Test Display',
          driverLicense: driverLicense,
          email: email,
          format: BarcodeFormat.qrCode,
          geoPoint: geoPoint,
          phone: phone,
          rawBytes: rawBytes,
          rawValue: 'Test Raw Value',
          size: const Size(200, 200),
          sms: sms,
          type: BarcodeType.url,
          url: url,
          wifi: wifi,
        );

        expect(barcode.calendarEvent?.summary, 'Meeting');
        expect(barcode.contactInfo, isNotNull);
        expect(barcode.corners, hasLength(4));
        expect(barcode.displayValue, 'Test Display');
        expect(barcode.driverLicense?.firstName, 'John');
        expect(barcode.email?.address, 'test@example.com');
        expect(barcode.format, BarcodeFormat.qrCode);
        expect(barcode.geoPoint?.latitude, 37.7749);
        expect(barcode.phone?.number, '+1234567890');
        expect(barcode.rawBytes, rawBytes);
        expect(barcode.rawValue, 'Test Raw Value');
        expect(barcode.size, const Size(200, 200));
        expect(barcode.sms?.message, 'Hello');
        expect(barcode.type, BarcodeType.url);
        expect(barcode.url?.url, 'https://example.com');
        expect(barcode.wifi?.ssid, 'TestNetwork');
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

      test('creates instance with displayValue and rawValue', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'displayValue': 'https://example.com',
          'rawValue': 'MEBKM:URL:https://example.com;;',
        });

        expect(barcode.displayValue, 'https://example.com');
        expect(barcode.rawValue, 'MEBKM:URL:https://example.com;;');
      });

      test('creates instance with rawBytes', () {
        final rawBytes = Uint8List.fromList([72, 101, 108, 108, 111]);
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'rawBytes': rawBytes,
        });

        expect(barcode.rawBytes, rawBytes);
      });

      test('creates instance with format', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'format': BarcodeFormat.qrCode.rawValue,
        });

        expect(barcode.format, BarcodeFormat.qrCode);
      });

      test('creates instance with unknown format when missing', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'format': null,
        });

        expect(barcode.format, BarcodeFormat.unknown);
      });

      test('creates instance with type', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'type': BarcodeType.url.rawValue,
        });

        expect(barcode.type, BarcodeType.url);
      });

      test('creates instance with unknown type when missing', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'type': null,
        });

        expect(barcode.type, BarcodeType.unknown);
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

      test('creates instance with zero size when size is missing', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'size': null,
        });

        expect(barcode.size, Size.zero);
      });

      test('creates instance with zero size when width is missing', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'size': <Object?, Object?>{
            'width': null,
            'height': 50.0,
          },
        });

        expect(barcode.size, Size.zero);
      });

      test('creates instance with zero size when height is missing', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'size': <Object?, Object?>{
            'width': 100.0,
            'height': null,
          },
        });

        expect(barcode.size, Size.zero);
      });

      test('creates instance with corners', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'corners': <Object?>[
            <Object?, Object?>{'x': 0.0, 'y': 0.0},
            <Object?, Object?>{'x': 100.0, 'y': 0.0},
            <Object?, Object?>{'x': 100.0, 'y': 100.0},
            <Object?, Object?>{'x': 0.0, 'y': 100.0},
          ],
        });

        expect(barcode.corners, hasLength(4));
        expect(barcode.corners[0], Offset.zero);
        expect(barcode.corners[1], const Offset(100, 0));
        expect(barcode.corners[2], const Offset(100, 100));
        expect(barcode.corners[3], const Offset(0, 100));
      });

      test('creates instance with empty corners when null', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'corners': null,
        });

        expect(barcode.corners, isEmpty);
      });

      test('creates instance with calendarEvent', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'calendarEvent': <Object?, Object?>{
            'summary': 'Team Meeting',
            'description': 'Weekly standup',
            'location': 'Conference Room A',
          },
        });

        expect(barcode.calendarEvent, isNotNull);
        expect(barcode.calendarEvent?.summary, 'Team Meeting');
        expect(barcode.calendarEvent?.description, 'Weekly standup');
        expect(barcode.calendarEvent?.location, 'Conference Room A');
      });

      test('creates instance with contactInfo', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'contactInfo': <Object?, Object?>{
            'name': <Object?, Object?>{
              'first': 'John',
              'last': 'Doe',
            },
          },
        });

        expect(barcode.contactInfo, isNotNull);
        expect(barcode.contactInfo?.name?.first, 'John');
        expect(barcode.contactInfo?.name?.last, 'Doe');
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
        expect(barcode.driverLicense?.firstName, 'John');
        expect(barcode.driverLicense?.lastName, 'Doe');
        expect(barcode.driverLicense?.licenseNumber, 'D1234567');
      });

      test('creates instance with email', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'email': <Object?, Object?>{
            'address': 'test@example.com',
            'subject': 'Hello',
            'body': 'Test message',
          },
        });

        expect(barcode.email, isNotNull);
        expect(barcode.email?.address, 'test@example.com');
        expect(barcode.email?.subject, 'Hello');
        expect(barcode.email?.body, 'Test message');
      });

      test('creates instance with geoPoint', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'geoPoint': <Object?, Object?>{
            'latitude': 37.7749,
            'longitude': -122.4194,
          },
        });

        expect(barcode.geoPoint, isNotNull);
        expect(barcode.geoPoint?.latitude, 37.7749);
        expect(barcode.geoPoint?.longitude, -122.4194);
      });

      test('creates instance with phone', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'phone': <Object?, Object?>{
            'number': '+1-555-123-4567',
            'type': 4,
          },
        });

        expect(barcode.phone, isNotNull);
        expect(barcode.phone?.number, '+1-555-123-4567');
      });

      test('creates instance with sms', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'sms': <Object?, Object?>{
            'message': 'Hello World',
            'phoneNumber': '+1234567890',
          },
        });

        expect(barcode.sms, isNotNull);
        expect(barcode.sms?.message, 'Hello World');
        expect(barcode.sms?.phoneNumber, '+1234567890');
      });

      test('creates instance with url', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'url': <Object?, Object?>{
            'title': 'Google',
            'url': 'https://www.google.com',
          },
        });

        expect(barcode.url, isNotNull);
        expect(barcode.url?.title, 'Google');
        expect(barcode.url?.url, 'https://www.google.com');
      });

      test('creates instance with wifi', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'wifi': <Object?, Object?>{
            'ssid': 'TestNetwork',
            'password': 'secret123',
            'encryptionType': 2,
          },
        });

        expect(barcode.wifi, isNotNull);
        expect(barcode.wifi?.ssid, 'TestNetwork');
        expect(barcode.wifi?.password, 'secret123');
      });

      test('creates instance with all embedded data types', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'displayValue': 'Complete Barcode',
          'rawValue': 'RAW_DATA',
          'format': BarcodeFormat.qrCode.rawValue,
          'type': BarcodeType.contactInfo.rawValue,
          'size': <Object?, Object?>{
            'width': 200.0,
            'height': 200.0,
          },
          'corners': <Object?>[
            <Object?, Object?>{'x': 10.0, 'y': 10.0},
            <Object?, Object?>{'x': 190.0, 'y': 10.0},
            <Object?, Object?>{'x': 190.0, 'y': 190.0},
            <Object?, Object?>{'x': 10.0, 'y': 190.0},
          ],
          'calendarEvent': <Object?, Object?>{'summary': 'Event'},
          'contactInfo': <Object?, Object?>{},
          'driverLicense': <Object?, Object?>{'firstName': 'Jane'},
          'email': <Object?, Object?>{'address': 'jane@example.com'},
          'geoPoint': <Object?, Object?>{
            'latitude': 40.7128,
            'longitude': -74.0060,
          },
          'phone': <Object?, Object?>{'number': '+1987654321'},
          'sms': <Object?, Object?>{'message': 'SMS Test'},
          'url': <Object?, Object?>{'url': 'https://test.com'},
          'wifi': <Object?, Object?>{'ssid': 'WiFiNetwork'},
        });

        expect(barcode.displayValue, 'Complete Barcode');
        expect(barcode.rawValue, 'RAW_DATA');
        expect(barcode.format, BarcodeFormat.qrCode);
        expect(barcode.type, BarcodeType.contactInfo);
        expect(barcode.size, const Size(200, 200));
        expect(barcode.corners, hasLength(4));
        expect(barcode.calendarEvent?.summary, 'Event');
        expect(barcode.contactInfo, isNotNull);
        expect(barcode.driverLicense?.firstName, 'Jane');
        expect(barcode.email?.address, 'jane@example.com');
        expect(barcode.geoPoint?.latitude, 40.7128);
        expect(barcode.phone?.number, '+1987654321');
        expect(barcode.sms?.message, 'SMS Test');
        expect(barcode.url?.url, 'https://test.com');
        expect(barcode.wifi?.ssid, 'WiFiNetwork');
      });

      test('handles all barcode formats', () {
        for (final format in BarcodeFormat.values) {
          // BarcodeFormat.itf is a deprecated alias for itf14,
          // sharing the same rawValue (128). Skip it to avoid
          // the ambiguous reverse lookup.
          if (format == BarcodeFormat.itf) {
            continue;
          }

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

      test('handles all barcode types', () {
        for (final type in BarcodeType.values) {
          final barcode = Barcode.fromNative(<Object?, Object?>{
            'type': type.rawValue,
          });

          expect(
            barcode.type,
            type,
            reason: 'Type with raw value ${type.rawValue} should map to $type',
          );
        }
      });

      test('handles Unicode in displayValue and rawValue', () {
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'displayValue': '日本語テスト',
          'rawValue': 'Ümläüte ñ ç',
        });

        expect(barcode.displayValue, '日本語テスト');
        expect(barcode.rawValue, 'Ümläüte ñ ç');
      });

      test('handles very long rawValue', () {
        final longValue = 'A' * 10000;
        final barcode = Barcode.fromNative(<Object?, Object?>{
          'rawValue': longValue,
        });

        expect(barcode.rawValue?.length, 10000);
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
