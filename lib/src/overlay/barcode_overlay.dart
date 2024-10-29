import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeOverlay extends StatelessWidget {
  const BarcodeOverlay({
    super.key,
    required this.controller,
    required this.boxFit,
  });

  final MobileScannerController controller;
  final BoxFit boxFit;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        // Not ready.
        if (!value.isInitialized || !value.isRunning || value.error != null) {
          return const SizedBox();
        }

        return StreamBuilder<BarcodeCapture>(
          stream: controller.barcodes,
          builder: (context, snapshot) {
            final BarcodeCapture? barcodeCapture = snapshot.data;

            // No barcode.
            if (barcodeCapture == null || barcodeCapture.barcodes.isEmpty) {
              return const SizedBox();
            }

            final overlays = <Widget>[];

            for (final scannedBarcode in barcodeCapture.barcodes) {
              // No barcode corners, or size, or no camera preview size.
              if (value.size.isEmpty ||
                  scannedBarcode.size.isEmpty ||
                  scannedBarcode.corners.isEmpty) {
                continue;
              }

              overlays.add(
                CustomPaint(
                  painter: BarcodePainter(
                    barcodeCorners: scannedBarcode.corners,
                    barcodeSize: scannedBarcode.size,
                    boxFit: boxFit,
                    cameraPreviewSize: barcodeCapture.size,
                  ),
                ),
              );
            }

            return Stack(
              fit: StackFit.expand,
              children: overlays,
            );
          },
        );
      },
    );
  }
}
