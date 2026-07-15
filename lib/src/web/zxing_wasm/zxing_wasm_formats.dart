import 'package:mobile_scanner/src/enums/barcode_format.dart';

/// Maps a zxing-wasm format string to [BarcodeFormat].
extension ZXingWasmFormatStringToBarcodeFormat on String {
  /// Converts a zxing-wasm format string (e.g. `'QRCode'`) to a
  /// [BarcodeFormat] enum value.
  BarcodeFormat get toBarcodeFormat => switch (this) {
    'Aztec' => BarcodeFormat.aztec,
    'Codabar' => BarcodeFormat.codabar,
    'Code39' => BarcodeFormat.code39,
    'Code93' => BarcodeFormat.code93,
    'Code128' => BarcodeFormat.code128,
    'DataMatrix' => BarcodeFormat.dataMatrix,
    'EAN-8' => BarcodeFormat.ean8,
    'EAN-13' => BarcodeFormat.ean13,
    'ITF' => BarcodeFormat.itf,
    'PDF417' => BarcodeFormat.pdf417,
    'QRCode' => BarcodeFormat.qrCode,
    'UPC-A' => BarcodeFormat.upcA,
    'UPC-E' => BarcodeFormat.upcE,
    _ => BarcodeFormat.unknown,
  };
}

/// Maps a [BarcodeFormat] to a zxing-wasm format string, or `null` if the
/// format is not supported by zxing-wasm.
extension BarcodeFormatToZXingWasmString on BarcodeFormat {
  /// Converts a [BarcodeFormat] to a zxing-wasm format string
  /// (e.g. `'QRCode'`), or `null` if the format is not supported.
  String? get toZXingWasmString => switch (this) {
    BarcodeFormat.aztec => 'Aztec',
    BarcodeFormat.codabar => 'Codabar',
    BarcodeFormat.code39 => 'Code39',
    BarcodeFormat.code93 => 'Code93',
    BarcodeFormat.code128 => 'Code128',
    BarcodeFormat.dataMatrix => 'DataMatrix',
    BarcodeFormat.ean8 => 'EAN-8',
    BarcodeFormat.ean13 => 'EAN-13',
    BarcodeFormat.itf ||
    BarcodeFormat.itf14 ||
    BarcodeFormat.itf2of5 ||
    BarcodeFormat.itf2of5WithChecksum => 'ITF',
    BarcodeFormat.pdf417 => 'PDF417',
    BarcodeFormat.qrCode => 'QRCode',
    BarcodeFormat.upcA => 'UPC-A',
    BarcodeFormat.upcE => 'UPC-E',
    BarcodeFormat.all || BarcodeFormat.unknown || _ => null,
  };
}
