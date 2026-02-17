import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/encryption_type.dart';
import 'package:mobile_scanner/src/objects/wifi.dart';

void main() {
  group('$WiFi tests', () {
    group('constructor', () {
      test('creates instance with default values', () {
        const wifi = WiFi();

        expect(wifi.encryptionType, EncryptionType.unknown);
        expect(wifi.ssid, isNull);
        expect(wifi.password, isNull);
      });

      test('creates instance with all values provided', () {
        const wifi = WiFi(
          encryptionType: EncryptionType.wpa,
          ssid: 'MyNetwork',
          password: 'secret123',
        );

        expect(wifi.encryptionType, EncryptionType.wpa);
        expect(wifi.ssid, 'MyNetwork');
        expect(wifi.password, 'secret123');
      });
    });

    group('fromNative', () {
      test('creates instance with empty map', () {
        final wifi = WiFi.fromNative(<Object?, Object?>{});

        expect(wifi.encryptionType, EncryptionType.unknown);
        expect(wifi.ssid, isNull);
        expect(wifi.password, isNull);
      });

      test('creates instance with all values', () {
        final wifi = WiFi.fromNative(<Object?, Object?>{
          'encryptionType': 2,
          'ssid': 'MyNetwork',
          'password': 'secret123',
        });

        expect(wifi.encryptionType, EncryptionType.wpa);
        expect(wifi.ssid, 'MyNetwork');
        expect(wifi.password, 'secret123');
      });

      test(
        'creates instance with null encryption type defaults to unknown',
        () {
          final wifi = WiFi.fromNative(<Object?, Object?>{
            'ssid': 'MyNetwork',
            'encryptionType': null,
          });

          expect(wifi.ssid, 'MyNetwork');
          expect(wifi.encryptionType, EncryptionType.unknown);
        },
      );

      test(
        'creates instance with missing encryption type defaults to unknown',
        () {
          final wifi = WiFi.fromNative(<Object?, Object?>{
            'ssid': 'MyNetwork',
          });

          expect(wifi.ssid, 'MyNetwork');
          expect(wifi.encryptionType, EncryptionType.unknown);
        },
      );

      test('creates instance with all encryption types', () {
        for (final type in EncryptionType.values) {
          final wifi = WiFi.fromNative(<Object?, Object?>{
            'encryptionType': type.rawValue,
          });

          expect(
            wifi.encryptionType,
            type,
            reason: 'Type with raw value ${type.rawValue} should map to $type',
          );
        }
      });

      test('creates instance with null ssid and password', () {
        final wifi = WiFi.fromNative(<Object?, Object?>{
          'ssid': null,
          'password': null,
          'encryptionType': 1,
        });

        expect(wifi.ssid, isNull);
        expect(wifi.password, isNull);
        expect(wifi.encryptionType, EncryptionType.open);
      });

      test('creates WEP encrypted network', () {
        final wifi = WiFi.fromNative(<Object?, Object?>{
          'encryptionType': 3,
          'ssid': 'LegacyNetwork',
          'password': 'wep_key',
        });

        expect(wifi.encryptionType, EncryptionType.wep);
        expect(wifi.ssid, 'LegacyNetwork');
        expect(wifi.password, 'wep_key');
      });
    });
  });
}
