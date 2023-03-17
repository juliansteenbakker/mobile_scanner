import 'dart:typed_data';

import 'package:mobile_scanner/src/objects/barcode.dart';

/// The return object after a frame is scanned.
///
/// [barcodes] A list with barcodes. A scanned frame can contain multiple
/// barcodes.
/// [image] If enabled, an image of the scanned frame.
class BarcodeCapture {
  final List<Barcode> barcodes;
  final dynamic raw;

  final Uint8List? image;

  final double? width;

  final double? height;

  BarcodeCapture({
    required this.barcodes,
    required this.raw,
    this.image,
    this.width,
    this.height,
  });
}
