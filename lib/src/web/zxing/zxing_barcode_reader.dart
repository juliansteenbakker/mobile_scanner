import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/web/barcode_reader.dart';
import 'package:mobile_scanner/src/web/zxing/zxing_browser_multi_format_reader.dart';

/// A barcode reader implementation that uses the ZXing library.
final class ZXingBarcodeReader extends BarcodeReader {
  ZXingBarcodeReader();

  /// The internal barcode reader.
  ZXingBrowserMultiFormatReader? _reader;

  @override
  String get scriptUrl => 'https://unpkg.com/@zxing/library@0.19.1';

  /// Get the barcode format from the ZXing library, for the given [format].
  int getZXingBarcodeFormat(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.aztec:
        return 0;
      case BarcodeFormat.codabar:
        return 1;
      case BarcodeFormat.code39:
        return 2;
      case BarcodeFormat.code93:
        return 3;
      case BarcodeFormat.code128:
        return 4;
      case BarcodeFormat.dataMatrix:
        return 5;
      case BarcodeFormat.ean8:
        return 6;
      case BarcodeFormat.ean13:
        return 7;
      case BarcodeFormat.itf:
        return 8;
      case BarcodeFormat.pdf417:
        return 10;
      case BarcodeFormat.qrCode:
        return 11;
      case BarcodeFormat.upcA:
        return 14;
      case BarcodeFormat.upcE:
        return 15;
      case BarcodeFormat.unknown:
      case BarcodeFormat.all:
        return -1;
    }
  }
}
