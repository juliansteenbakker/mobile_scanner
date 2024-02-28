import 'dart:typed_data';
import 'dart:ui';

import 'package:mobile_scanner/src/objects/barcode.dart';

/// This class represents a scanned barcode.
class BarcodeCapture {
  /// Create a new [BarcodeCapture] instance.
  const BarcodeCapture({
    this.barcodes = const <Barcode>[],
    this.image,
    this.raw,
    this.size = Size.zero,
  });

  /// The list of scanned barcodes.
  final List<Barcode> barcodes;

  /// The bytes of the image that is embedded in the barcode.
  ///
  /// This null if [MobileScannerController.returnImage] is false,
  /// or if there is no available image.
  final Uint8List? image;

  /// The raw data of the scanned barcode.
  final Object? raw;

  /// The size of the scanned barcode.
  final Size size;
}
