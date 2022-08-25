import 'dart:typed_data';

import 'package:mobile_scanner/src/objects/barcode.dart';

class BarcodeCapture {
  List<Barcode> barcodes;
  Uint8List image;

  BarcodeCapture({
    required this.barcodes,
    required this.image
});

}