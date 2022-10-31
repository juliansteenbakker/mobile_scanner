import 'dart:typed_data';

import 'package:mobile_scanner/src/barcode.dart';

class BarcodeCapture {
  List<Barcode> barcodes;
  Uint8List? image;

  BarcodeCapture({
    required this.barcodes,
    this.image,
  });
}
