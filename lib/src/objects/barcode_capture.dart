import 'dart:typed_data';
import 'dart:ui';

import 'package:mobile_scanner/src/objects/barcode.dart';

/// This class represents a scanned barcode.
class BarcodeCapture {
  /// Create a new [BarcodeCapture] instance.
  BarcodeCapture({
    this.barcodes = const <Barcode>[],
    double? height,
    this.image,
    this.raw,
    double? width,
  }) : size =
            width == null && height == null ? Size.zero : Size(width!, height!);

  /// The list of scanned barcodes.
  final List<Barcode> barcodes;

  /// The bytes of the image that is embedded in the barcode.
  ///
  /// This null if [MobileScannerController.returnImage] is false.
  final Uint8List? image;

  /// The raw data of the scanned barcode.
  final dynamic raw; // TODO: this should be `Object?` instead of dynamic

  /// The size of the scanned barcode.
  final Size size;

  /// The width of the scanned barcode.
  ///
  /// Prefer using `size.width` instead,
  /// as this getter will be removed in the future.
  double get width => size.width;

  /// The height of the scanned barcode.
  ///
  /// Prefer using `size.height` instead,
  /// as this getter will be removed in the future.
  double get height => size.height;
}
