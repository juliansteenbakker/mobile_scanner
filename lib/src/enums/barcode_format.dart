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
