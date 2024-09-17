import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/picklist/widgets/barcode_overlay.dart';

List<Widget> drawDetectedBarcodes({
  required List<Barcode>? barcodes,
  required Size cameraPreviewSize,
  required BoxFit fit,
}) {
  final barcodeWidgets = <Widget>[];
  if (barcodes == null || barcodes.isEmpty) {
    debugPrint('EMPTY!!!');
  }
  if (barcodes != null) {
    for (final barcode in barcodes) {
      barcodeWidgets.add(
        CustomPaint(
          painter: BarcodeOverlay(
            barcodeCorners: barcode.corners,
            barcodeSize: barcode.size,
            boxFit: fit,
            cameraPreviewSize: cameraPreviewSize,
          ),
        ),
      );
      debugPrint(
        'barcodeCorners => ${barcode.corners.map((e) => 'x: ${e.dx}, y: ${e.dy} ')}, barcodeSize => width: ${barcode.size.width}, height: ${barcode.size.height}, cameraPreviewSize => width: ${cameraPreviewSize.width}, height: ${cameraPreviewSize.height} ',
      );
    }
    debugPrint(barcodeWidgets.length.toString());
  }
  return barcodeWidgets;
}
