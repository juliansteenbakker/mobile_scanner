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
