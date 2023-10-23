/// This enum defines the different barcode formats.
enum BarcodeFormat {
  /// A barcode format that represents all unknown formats.
  unknown(-1),

  /// A barcode format that represents all known formats.
  all(0),

  /// Barcode format constant for Code 128.
  code128(1),

  /// Barcode format constant for Code 39.
  code39(2),

  /// Barcode format constant for Code 93.
  code93(4),

  /// Barcode format constant for Codabar.
  codabar(8),

  /// Barcode format constant for Data Matrix.
  dataMatrix(16),

  /// Barcode format constant for EAN-13.
  ean13(32),

  /// Barcode format constant for EAN-8.
  ean8(64),

  /// Barcode format constant for ITF (Interleaved Two-of-Five).
  itf(128),

  /// Barcode format constant for QR Codes.
  qrCode(256),

  /// Barcode format constant for UPC-A.
  upcA(512),

  /// Barcode format constant for UPC-E.
  upcE(1024),

  /// Barcode format constant for PDF-417.
  pdf417(2048),

  /// Barcode format constant for AZTEC.
  aztec(4096);

  /// This constant represents the old value for [BarcodeFormat.codabar].
  ///
  /// Prefer using the new [BarcodeFormat.codabar] constant,
  /// as the `codebar` value will be removed in a future release.
  static const BarcodeFormat codebar = codabar;

  const BarcodeFormat(this.rawValue);

  factory BarcodeFormat.fromRawValue(int value) {
    switch (value) {
      case -1:
        return BarcodeFormat.unknown;
      case 0:
        return BarcodeFormat.all;
      case 1:
        return BarcodeFormat.code128;
      case 2:
        return BarcodeFormat.code39;
      case 4:
        return BarcodeFormat.code93;
      case 8:
        return BarcodeFormat.codebar;
      case 16:
        return BarcodeFormat.dataMatrix;
      case 32:
        return BarcodeFormat.ean13;
      case 64:
        return BarcodeFormat.ean8;
      case 128:
        return BarcodeFormat.itf;
      case 256:
        return BarcodeFormat.qrCode;
      case 512:
        return BarcodeFormat.upcA;
      case 1024:
        return BarcodeFormat.upcE;
      case 2048:
        return BarcodeFormat.pdf417;
      case 4096:
        return BarcodeFormat.aztec;
      default:
        throw ArgumentError.value(value, 'value', 'Invalid raw value.');
    }
  }

  /// The raw value of the barcode format.
  final int rawValue;
}
