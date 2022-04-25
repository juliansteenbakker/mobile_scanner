import 'dart:typed_data';
import 'dart:ui';

import 'package:mobile_scanner/src/objects/barcode_utility.dart';

/// Represents a single recognized barcode and its value.
class Barcode {
  /// Returns four corner points in clockwise direction starting with top-left.
  ///
  /// Due to the possible perspective distortions, this is not necessarily a rectangle.
  ///
  /// Returns null if the corner points can not be determined.
  final List<Offset>? corners;

  /// Returns barcode format
  final BarcodeFormat format;

  /// Returns raw bytes as it was encoded in the barcode.
  ///
  /// Returns null if the raw bytes can not be determined.
  final Uint8List? rawBytes;

  /// Returns barcode value as it was encoded in the barcode. Structured values are not parsed, for example: 'MEBKM:TITLE:Google;URL://www.google.com;;'.
  ///
  /// It's only available when the barcode is encoded in the UTF-8 format, and for non-UTF8 ones use [rawBytes] instead.
  ///
  /// Returns null if the raw value can not be determined.
  final String? rawValue;

  /// Returns format type of the barcode value.
  ///
  /// For example, TYPE_TEXT, TYPE_PRODUCT, TYPE_URL, etc.
  ///
  /// If the value structure cannot be parsed, TYPE_TEXT will be returned. If the recognized structure type is not defined in your current version of SDK, TYPE_UNKNOWN will be returned.
  ///
  /// Note that the built-in parsers only recognize a few popular value structures. For your specific use case, you might want to directly consume rawValue and implement your own parsing logic.
  final BarcodeType type;

  /// Gets parsed calendar event details.
  final CalendarEvent? calendarEvent;

  /// Gets parsed contact details.
  final ContactInfo? contactInfo;

  /// Gets parsed driver license details.
  final DriverLicense? driverLicense;

  /// Gets parsed email details.
  final Email? email;

  /// Gets parsed geo coordinates.
  final GeoPoint? geoPoint;

  /// Gets parsed phone number details.
  final Phone? phone;

  /// Gets parsed SMS details.
  final SMS? sms;

  /// Gets parsed URL bookmark details.
  final UrlBookmark? url;

  /// Gets parsed WiFi AP details.
  final WiFi? wifi;

  Barcode({
    this.corners,
    this.format = BarcodeFormat.ean13,
    this.rawBytes,
    this.type = BarcodeType.text,
    this.calendarEvent,
    this.contactInfo,
    this.driverLicense,
    this.email,
    this.geoPoint,
    this.phone,
    this.sms,
    this.url,
    this.wifi,
    required this.rawValue,
  });

  /// Create a [Barcode] from native data.
  Barcode.fromNative(Map data)
      : corners = toCorners(data['corners'] as List?),
        format = toFormat(data['format'] as int),
        rawBytes = data['rawBytes'] as Uint8List?,
        rawValue = data['rawValue'] as String?,
        type = BarcodeType.values[data['type'] as int],
        calendarEvent = toCalendarEvent(data['calendarEvent'] as Map?),
        contactInfo = toContactInfo(data['contactInfo'] as Map?),
        driverLicense = toDriverLicense(data['driverLicense'] as Map?),
        email = toEmail(data['email'] as Map?),
        geoPoint = toGeoPoint(data['geoPoint'] as Map?),
        phone = toPhone(data['phone'] as Map?),
        sms = toSMS(data['sms'] as Map?),
        url = toUrl(data['url'] as Map?),
        wifi = toWiFi(data['wifi'] as Map?);
}

/// A calendar event extracted from QRCode.
class CalendarEvent {
  /// Gets the description of the calendar event.
  ///
  /// Returns null if not available.
  final String? description;

  /// Gets the start date time of the calendar event.
  ///
  /// Returns null if not available.
  final DateTime? start;

  /// Gets the end date time of the calendar event.
  ///
  /// Returns null if not available.
  final DateTime? end;

  /// Gets the location of the calendar event.
  ///
  /// Returns null if not available.
  final String? location;

  /// Gets the organizer of the calendar event.
  ///
  /// Returns null if not available.
  final String? organizer;

  /// Gets the status of the calendar event.
  ///
  /// Returns null if not available.
  final String? status;

  /// Gets the summary of the calendar event.
  ///
  /// Returns null if not available.
  final String? summary;

  /// Create a [CalendarEvent] from native data.
  CalendarEvent.fromNative(Map data)
      : description = data['description'] as String?,
        start = data['start'] != null
            ? DateTime.tryParse(data['start'] as String)
            : null,
        end = data['end'] != null
            ? DateTime.tryParse(data['end'] as String)
            : null,
        location = data['location'] as String?,
        organizer = data['organizer'] as String?,
        status = data['status'] as String?,
        summary = data['summary'] as String?;
}

/// A person's or organization's business card. For example a VCARD.
class ContactInfo {
  /// Gets contact person's addresses.
  ///
  /// Returns an empty list if nothing found.
  final List<Address> addresses;

  /// Gets contact person's emails.
  ///
  /// Returns an empty list if nothing found.
  final List<Email> emails;

  /// Gets contact person's name.
  ///
  /// Returns null if not available.
  final PersonName? name;

  /// Gets contact person's organization.
  ///
  /// Returns null if not available.
  final String? organization;

  /// Gets contact person's phones.
  ///
  /// Returns an empty list if nothing found.
  final List<Phone>? phones;

  /// Gets contact person's title.
  ///
  /// Returns null if not available.
  final String? title;

  /// Gets contact person's urls.
  ///
  /// Returns an empty list if nothing found.
  final List<String>? urls;

  /// Create a [ContactInfo] from native data.
  ContactInfo.fromNative(Map data)
      : addresses = List.unmodifiable(
          (data['addresses'] as List).map((e) => Address.fromNative(e as Map)),
        ),
        emails = List.unmodifiable(
          (data['emails'] as List).map((e) => Email.fromNative(e as Map)),
        ),
        name = toName(data['name'] as Map?),
        organization = data['organization'] as String?,
        phones = List.unmodifiable(
          (data['phones'] as List).map((e) => Phone.fromNative(e as Map)),
        ),
        title = data['title'] as String?,
        urls = List.unmodifiable(data['urls'] as List);
}

/// An address.
class Address {
  /// Gets formatted address, multiple lines when appropriate. This field always contains at least one line.
  final List<String> addressLines;

  /// Gets type of the address.
  ///
  /// Returns null if not available.
  final AddressType? type;

  /// Create a [Address] from native data.
  Address.fromNative(Map data)
      : addressLines = List.unmodifiable(data['addressLines'] as List),
        type = AddressType.values[data['type'] as int];
}

/// A person's name, both formatted version and individual name components.
class PersonName {
  /// Gets first name.
  ///
  /// Returns null if not available.
  final String? first;

  /// Gets middle name.
  ///
  /// Returns null if not available.
  final String? middle;

  /// Gets last name.
  ///
  /// Returns null if not available.
  final String? last;

  /// Gets prefix of the name.
  ///
  /// Returns null if not available.
  final String? prefix;

  /// Gets suffix of the person's name.
  ///
  /// Returns null if not available.
  final String? suffix;

  /// Gets the properly formatted name.
  ///
  /// Returns null if not available.
  final String? formattedName;

  /// Designates a text string to be set as the kana name in the phonebook. Used for Japanese contacts.
  ///
  /// Returns null if not available.
  final String? pronunciation;

  /// Create a [PersonName] from native data.
  PersonName.fromNative(Map data)
      : first = data['first'] as String?,
        middle = data['middle'] as String?,
        last = data['last'] as String?,
        prefix = data['prefix'] as String?,
        suffix = data['suffix'] as String?,
        formattedName = data['formattedName'] as String?,
        pronunciation = data['pronunciation'] as String?;
}

/// A driver license or ID card.
class DriverLicense {
  /// Gets city of holder's address.
  ///
  /// Returns null if not available.
  final String? addressCity;

  /// Gets state of holder's address.
  ///
  /// Returns null if not available.
  final String? addressState;

  /// Gets holder's street address.
  ///
  /// Returns null if not available.
  final String? addressStreet;

  /// Gets postal code of holder's address.
  ///
  /// Returns null if not available.
  final String? addressZip;

  /// Gets birth date of the holder.
  ///
  /// Returns null if not available.
  final String? birthDate;

  /// Gets "DL" for driver licenses, "ID" for ID cards.
  ///
  /// Returns null if not available.
  final String? documentType;

  /// Gets expiry date of the license.
  ///
  /// Returns null if not available.
  final String? expiryDate;

  /// Gets holder's first name.
  ///
  /// Returns null if not available.
  final String? firstName;

  /// Gets holder's gender. 1 - male, 2 - female.
  ///
  /// Returns null if not available.
  final String? gender;

  /// Gets issue date of the license.
  ///
  /// The date format depends on the issuing country. MMDDYYYY for the US, YYYYMMDD for Canada.
  ///
  /// Returns null if not available.
  final String? issueDate;

  /// Gets the three-letter country code in which DL/ID was issued.
  ///
  /// Returns null if not available.
  final String? issuingCountry;

  /// Gets holder's last name.
  ///
  /// Returns null if not available.
  final String? lastName;

  /// Gets driver license ID number.
  ///
  /// Returns null if not available.
  final String? licenseNumber;

  /// Gets holder's middle name.
  ///
  /// Returns null if not available.
  final String? middleName;

  /// Create a [DriverLicense] from native data.
  DriverLicense.fromNative(Map data)
      : addressCity = data['addressCity'] as String?,
        addressState = data['addressState'] as String?,
        addressStreet = data['addressStreet'] as String?,
        addressZip = data['addressZip'] as String?,
        birthDate = data['birthDate'] as String?,
        documentType = data['documentType'] as String?,
        expiryDate = data['expiryDate'] as String?,
        firstName = data['firstName'] as String?,
        gender = data['gender'] as String?,
        issueDate = data['issueDate'] as String?,
        issuingCountry = data['issuingCountry'] as String?,
        lastName = data['lastName'] as String?,
        licenseNumber = data['licenseNumber'] as String?,
        middleName = data['middleName'] as String?;
}

/// An email message from a 'MAILTO:' or similar QRCode type.
class Email {
  /// Gets email's address.
  ///
  /// Returns null if not available.
  final String? address;

  /// Gets email's body.
  ///
  /// Returns null if not available.
  final String? body;

  /// Gets email's subject.
  ///
  /// Returns null if not available.
  final String? subject;

  /// Gets type of the email.
  ///
  /// See also [EmailType].
  /// Returns null if not available.
  final EmailType? type;

  /// Create a [Email] from native data.
  Email.fromNative(Map data)
      : address = data['address'] as String?,
        body = data['body'] as String?,
        subject = data['subject'] as String?,
        type = EmailType.values[data['type'] as int];
}

/// GPS coordinates from a 'GEO:' or similar QRCode type.
class GeoPoint {
  /// Gets the latitude.
  final double? latitude;

  /// Gets the longitude.
  final double? longitude;

  /// Create a [GeoPoint] from native data.
  GeoPoint.fromNative(Map data)
      : latitude = data['latitude'] as double?,
        longitude = data['longitude'] as double?;
}

/// Phone number info.
class Phone {
  /// Gets phone number.
  ///
  /// Returns null if not available.
  final String? number;

  /// Gets type of the phone number.
  ///
  /// See also [PhoneType].
  /// Returns null if not available.
  final PhoneType? type;

  /// Create a [Phone] from native data.
  Phone.fromNative(Map data)
      : number = data['number'] as String?,
        type = PhoneType.values[data['type'] as int];
}

/// A sms message from a 'SMS:' or similar QRCode type.
class SMS {
  /// Gets the message content of the sms.
  ///
  /// Returns null if not available.
  final String? message;

  /// Gets the phone number of the sms.
  ///
  /// Returns null if not available.
  final String? phoneNumber;

  /// Create a [SMS] from native data.
  SMS.fromNative(Map data)
      : message = data['message'] as String?,
        phoneNumber = data['phoneNumber'] as String?;
}

/// A URL and title from a 'MEBKM:' or similar QRCode type.
class UrlBookmark {
  /// Gets the title of the bookmark.
  ///
  /// Returns null if not available.
  final String? title;

  /// Gets the url of the bookmark.
  ///
  /// Returns null if not available.
  final String? url;

  /// Create a [UrlBookmark] from native data.
  UrlBookmark.fromNative(Map data)
      : title = data['title'] as String?,
        url = data['url'] as String?;
}

/// A wifi network parameters from a 'WIFI:' or similar QRCode type.
class WiFi {
  /// Gets the encryption type of the WIFI.
  ///
  /// See all [EncryptionType].
  final EncryptionType encryptionType;

  /// Gets the ssid of the WIFI.
  ///
  /// Returns null if not available.
  final String? ssid;

  /// Gets the password of the WIFI.
  ///
  /// Returns null if not available.
  final String? password;

  /// Create a [WiFi] from native data.
  WiFi.fromNative(Map data)
      : encryptionType = EncryptionType.values[data['encryptionType'] as int],
        ssid = data['ssid'] as String?,
        password = data['password'] as String?;
}

enum BarcodeFormat {
  /// Barcode format unknown to the current SDK.
  ///
  /// Constant Value: -1
  unknown,

  /// Barcode format constant representing the union of all supported formats.
  ///
  /// Constant Value: 0
  all,

  /// Barcode format constant for Code 128.
  ///
  /// Constant Value: 1
  code128,

  /// Barcode format constant for Code 39.
  ///
  /// Constant Value: 2
  code39,

  /// Barcode format constant for Code 93.
  ///
  /// Constant Value: 4
  code93,

  /// Barcode format constant for Codabar.
  ///
  /// Constant Value: 8
  codebar,

  /// Barcode format constant for Data Matrix.
  ///
  /// Constant Value: 16
  dataMatrix,

  /// Barcode format constant for EAN-13.
  ///
  /// Constant Value: 32
  ean13,

  /// Barcode format constant for EAN-8.
  ///
  /// Constant Value: 64
  ean8,

  /// Barcode format constant for ITF (Interleaved Two-of-Five).
  ///
  /// Constant Value: 128
  itf,

  /// Barcode format constant for QR Code.
  ///
  /// Constant Value: 256
  qrCode,

  /// Barcode format constant for UPC-A.
  ///
  /// Constant Value: 512
  upcA,

  /// Barcode format constant for UPC-E.
  ///
  /// Constant Value: 1024
  upcE,

  /// Barcode format constant for PDF-417.
  ///
  /// Constant Value: 2048
  pdf417,

  /// Barcode format constant for AZTEC.
  ///
  /// Constant Value: 4096
  aztec,
}

extension BarcodeValue on BarcodeFormat {
  int get rawValue {
    switch (this) {
      case BarcodeFormat.unknown:
        return -1;
      case BarcodeFormat.all:
        return 0;
      case BarcodeFormat.code128:
        return 1;
      case BarcodeFormat.code39:
        return 2;
      case BarcodeFormat.code93:
        return 4;
      case BarcodeFormat.codebar:
        return 8;
      case BarcodeFormat.dataMatrix:
        return 16;
      case BarcodeFormat.ean13:
        return 32;
      case BarcodeFormat.ean8:
        return 64;
      case BarcodeFormat.itf:
        return 128;
      case BarcodeFormat.qrCode:
        return 256;
      case BarcodeFormat.upcA:
        return 512;
      case BarcodeFormat.upcE:
        return 1024;
      case BarcodeFormat.pdf417:
        return 2048;
      case BarcodeFormat.aztec:
        return 4096;
    }
  }
}

/// Address type constants.
enum AddressType {
  /// Unknown address type.
  ///
  /// Constant Value: 0
  unknown,

  /// Work address.
  ///
  /// Constant Value: 1
  work,

  /// Home address.
  ///
  /// Constant Value: 2
  home,
}

/// Barcode value type constants
enum BarcodeType {
  /// Barcode value type unknown, which indicates the current version of SDK cannot recognize the structure of the barcode. Developers can inspect the raw value instead.
  ///
  /// Constant Value: 0
  unknown,

  /// Barcode value type constant for contact information.
  ///
  /// Constant Value: 1
  contactInfo,

  /// Barcode value type constant for email message details.
  ///
  /// Constant Value: 2
  email,

  /// Barcode value type constant for ISBNs.
  ///
  /// Constant Value: 3
  isbn,

  /// Barcode value type constant for phone numbers.
  ///
  /// Constant Value: 4
  phone,

  /// Barcode value type constant for product codes.
  ///
  /// Constant Value: 5
  product,

  /// Barcode value type constant for SMS details.
  ///
  /// Constant Value: 6
  sms,

  /// Barcode value type constant for plain text.
  ///
  ///Constant Value: 7
  text,

  /// Barcode value type constant for URLs/bookmarks.
  ///
  /// Constant Value: 8
  url,

  /// Barcode value type constant for WiFi access point details.
  ///
  /// Constant Value: 9
  wifi,

  /// Barcode value type constant for geographic coordinates.
  ///
  /// Constant Value: 10
  geo,

  /// Barcode value type constant for calendar events.
  ///
  /// Constant Value: 11
  calendarEvent,

  /// Barcode value type constant for driver's license data.
  ///
  /// Constant Value: 12
  driverLicense,
}

/// Email format type constants.
enum EmailType {
  /// Unknown email type.
  ///
  /// Constant Value: 0
  unknown,

  /// Work email.
  ///
  /// Constant Value: 1
  work,

  /// Home email.
  ///
  /// Constant Value: 2
  home,
}

/// Phone number format type constants.
enum PhoneType {
  /// Unknown phone type.
  ///
  /// Constant Value: 0
  unknown,

  /// Work phone.
  ///
  /// Constant Value: 1
  work,

  /// Home phone.
  ///
  /// Constant Value: 2
  home,

  /// Fax machine.
  ///
  /// Constant Value: 3
  fax,

  /// Mobile phone.
  ///
  /// Constant Value: 4
  mobile,
}

/// Wifi encryption type constants.
enum EncryptionType {
  /// Unknown encryption type.
  ///
  /// Constant Value: 0
  none,

  /// Not encrypted.
  ///
  /// Constant Value: 1
  open,

  /// WPA level encryption.
  ///
  /// Constant Value: 2
  wpa,

  /// WEP level encryption.
  ///
  /// Constant Value: 3
  wep,
}
