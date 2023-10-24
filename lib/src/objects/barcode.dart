import 'dart:typed_data';
import 'dart:ui';

import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/barcode_type.dart';
import 'package:mobile_scanner/src/objects/calendar_event.dart';
import 'package:mobile_scanner/src/objects/contact_info.dart';
import 'package:mobile_scanner/src/objects/driver_license.dart';
import 'package:mobile_scanner/src/objects/email.dart';
import 'package:mobile_scanner/src/objects/geo_point.dart';
import 'package:mobile_scanner/src/objects/phone.dart';
import 'package:mobile_scanner/src/objects/sms.dart';
import 'package:mobile_scanner/src/objects/url_bookmark.dart';
import 'package:mobile_scanner/src/objects/wifi.dart';

/// Represents a single recognized barcode and its value.
class Barcode {
  /// Creates a new [Barcode] instance.
  const Barcode({
    this.calendarEvent,
    this.contactInfo,
    this.corners = const <Offset>[],
    this.displayValue,
    this.driverLicense,
    this.email,
    this.format = BarcodeFormat.unknown,
    this.geoPoint,
    this.phone,
    this.rawBytes,
    this.rawValue,
    this.sms,
    this.type = BarcodeType.unknown,
    this.url,
    this.wifi,
  });

  /// Creates a new [Barcode] instance from the given [data].
  factory Barcode.fromNative(Map<Object?, Object?> data) {
    final Map<Object?, Object?>? calendarEvent =
        data['calendarEvent'] as Map<Object?, Object?>?;
    final List<Object?>? corners = data['corners'] as List<Object?>?;
    final Map<Object?, Object?>? contactInfo =
        data['contactInfo'] as Map<Object?, Object?>?;
    final Map<Object?, Object?>? driverLicense =
        data['driverLicense'] as Map<Object?, Object?>?;
    final Map<Object?, Object?>? email =
        data['email'] as Map<Object?, Object?>?;
    final Map<Object?, Object?>? geoPoint =
        data['geoPoint'] as Map<Object?, Object?>?;
    final Map<Object?, Object?>? phone =
        data['phone'] as Map<Object?, Object?>?;
    final Map<Object?, Object?>? sms = data['sms'] as Map<Object?, Object?>?;
    final Map<Object?, Object?>? url = data['url'] as Map<Object?, Object?>?;
    final Map<Object?, Object?>? wifi = data['wifi'] as Map<Object?, Object?>?;

    return Barcode(
      calendarEvent: calendarEvent == null
          ? null
          : CalendarEvent.fromNative(calendarEvent),
      contactInfo:
          contactInfo == null ? null : ContactInfo.fromNative(contactInfo),
      corners: corners == null
          ? const <Offset>[]
          : List.unmodifiable(
              corners
                  .cast<Map<Object?, Object?>>()
                  .map((Map<Object?, Object?> e) {
                final double x = e['x']! as double;
                final double y = e['y']! as double;

                return Offset(x, y);
              }),
            ),
      displayValue: data['displayValue'] as String?,
      driverLicense: driverLicense == null
          ? null
          : DriverLicense.fromNative(driverLicense),
      email: email == null ? null : Email.fromNative(email),
      format: BarcodeFormat.fromRawValue(data['format'] as int? ?? -1),
      geoPoint: geoPoint == null ? null : GeoPoint.fromNative(geoPoint),
      phone: phone == null ? null : Phone.fromNative(phone),
      rawBytes: data['rawBytes'] as Uint8List?,
      rawValue: data['rawValue'] as String?,
      sms: sms == null ? null : SMS.fromNative(sms),
      type: BarcodeType.fromRawValue(data['type'] as int? ?? 0),
      url: url == null ? null : UrlBookmark.fromNative(url),
      wifi: wifi == null ? null : WiFi.fromNative(wifi),
    );
  }

  /// The calendar event that is embedded in the barcode.
  final CalendarEvent? calendarEvent;

  /// The contact information that is embedded in the barcode.
  final ContactInfo? contactInfo;

  /// The four corner points of the barcode,
  /// in clockwise order, starting with the top-left point.
  ///
  /// Due to the possible perspective distortions, this is not necessarily a rectangle.
  ///
  /// This list is empty if the corners can not be determined.
  final List<Offset> corners;

  /// The barcode value in a user-friendly format.
  ///
  /// This value may omit some of the information encoded in the barcode.
  /// For example, if [rawValue] returns `MEBKM:TITLE:Google;URL://www.google.com;;`,
  /// the display value might be `//www.google.com`.
  ///
  /// This value may be multiline if line breaks are encoded in the barcode.
  /// This value may include the supplement value.
  ///
  /// This is null if there is no user-friendly value for the given barcode.
  final String? displayValue;

  /// The driver license information that is embedded in the barcode.
  final DriverLicense? driverLicense;

  /// The email message that is embedded in the barcode.
  final Email? email;

  /// The format of the barcode.
  final BarcodeFormat format;

  /// The geographic point that is embedded in the barcode.
  final GeoPoint? geoPoint;

  /// The phone number that is embedded in the barcode.
  final Phone? phone;

  /// The raw bytes of the barcode.
  ///
  /// This is null if the raw bytes are not available.
  final Uint8List? rawBytes;

  /// The raw value of `UTF-8` encoded barcodes.
  ///
  /// Structured values are not parsed,
  /// for example: 'MEBKM:TITLE:Google;URL://www.google.com;;'.
  ///
  /// For non-UTF-8 barcodes, prefer using [rawBytes] instead.
  ///
  /// This is null if the raw value is not available.
  final String? rawValue;

  /// The SMS message that is embedded in the barcode.
  final SMS? sms;

  /// The type of the [format] of the barcode.
  ///
  /// For types that are recognized,
  /// but could not be parsed correctly, [BarcodeType.text] will be returned.
  ///
  /// For types that are not recognised, [BarcodeType.unknown] will be returned.
  ///
  /// If a given barcode was not correctly identified,
  /// consider parsing [rawValue] manually instead.
  final BarcodeType type;

  /// The URL bookmark that is embedded in the barcode.
  final UrlBookmark? url;

  /// The Wireless network information that is embedded in the barcode.
  final WiFi? wifi;
}
