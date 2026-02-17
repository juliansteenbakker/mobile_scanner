import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/driver_license.dart';

void main() {
  group('$DriverLicense tests', () {
    group('constructor', () {
      test('creates instance with default null values', () {
        const license = DriverLicense();

        expect(license.addressCity, isNull);
        expect(license.addressState, isNull);
        expect(license.addressStreet, isNull);
        expect(license.addressZip, isNull);
        expect(license.birthDate, isNull);
        expect(license.documentType, isNull);
        expect(license.expiryDate, isNull);
        expect(license.firstName, isNull);
        expect(license.gender, isNull);
        expect(license.issueDate, isNull);
        expect(license.issuingCountry, isNull);
        expect(license.lastName, isNull);
        expect(license.licenseNumber, isNull);
        expect(license.middleName, isNull);
      });

      test('creates instance with all values provided', () {
        const license = DriverLicense(
          addressCity: 'San Francisco',
          addressState: 'CA',
          addressStreet: '123 Main St',
          addressZip: '94102',
          birthDate: '01151990',
          documentType: 'DL',
          expiryDate: '01152030',
          firstName: 'John',
          gender: '1',
          issueDate: '01152020',
          issuingCountry: 'USA',
          lastName: 'Doe',
          licenseNumber: 'D1234567',
          middleName: 'Michael',
        );

        expect(license.addressCity, 'San Francisco');
        expect(license.addressState, 'CA');
        expect(license.addressStreet, '123 Main St');
        expect(license.addressZip, '94102');
        expect(license.birthDate, '01151990');
        expect(license.documentType, 'DL');
        expect(license.expiryDate, '01152030');
        expect(license.firstName, 'John');
        expect(license.gender, '1');
        expect(license.issueDate, '01152020');
        expect(license.issuingCountry, 'USA');
        expect(license.lastName, 'Doe');
        expect(license.licenseNumber, 'D1234567');
        expect(license.middleName, 'Michael');
      });
    });

    group('fromNative', () {
      test('creates instance with empty map', () {
        final license = DriverLicense.fromNative(<Object?, Object?>{});

        expect(license.addressCity, isNull);
        expect(license.addressState, isNull);
        expect(license.addressStreet, isNull);
        expect(license.addressZip, isNull);
        expect(license.birthDate, isNull);
        expect(license.documentType, isNull);
        expect(license.expiryDate, isNull);
        expect(license.firstName, isNull);
        expect(license.gender, isNull);
        expect(license.issueDate, isNull);
        expect(license.issuingCountry, isNull);
        expect(license.lastName, isNull);
        expect(license.licenseNumber, isNull);
        expect(license.middleName, isNull);
      });

      test('creates instance with all values', () {
        final license = DriverLicense.fromNative(<Object?, Object?>{
          'addressCity': 'San Francisco',
          'addressState': 'CA',
          'addressStreet': '123 Main St',
          'addressZip': '94102',
          'birthDate': '01151990',
          'documentType': 'DL',
          'expiryDate': '01152030',
          'firstName': 'John',
          'gender': '1',
          'issueDate': '01152020',
          'issuingCountry': 'USA',
          'lastName': 'Doe',
          'licenseNumber': 'D1234567',
          'middleName': 'Michael',
        });

        expect(license.addressCity, 'San Francisco');
        expect(license.addressState, 'CA');
        expect(license.addressStreet, '123 Main St');
        expect(license.addressZip, '94102');
        expect(license.birthDate, '01151990');
        expect(license.documentType, 'DL');
        expect(license.expiryDate, '01152030');
        expect(license.firstName, 'John');
        expect(license.gender, '1');
        expect(license.issueDate, '01152020');
        expect(license.issuingCountry, 'USA');
        expect(license.lastName, 'Doe');
        expect(license.licenseNumber, 'D1234567');
        expect(license.middleName, 'Michael');
      });

      test('creates instance with null values', () {
        final license = DriverLicense.fromNative(<Object?, Object?>{
          'addressCity': null,
          'firstName': null,
          'lastName': null,
        });

        expect(license.addressCity, isNull);
        expect(license.firstName, isNull);
        expect(license.lastName, isNull);
      });

      test('creates ID card type', () {
        final license = DriverLicense.fromNative(<Object?, Object?>{
          'documentType': 'ID',
        });

        expect(license.documentType, 'ID');
      });

      test('creates instance with female gender', () {
        final license = DriverLicense.fromNative(<Object?, Object?>{
          'gender': '2',
        });

        expect(license.gender, '2');
      });
    });
  });
}
