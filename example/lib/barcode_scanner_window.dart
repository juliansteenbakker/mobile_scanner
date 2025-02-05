import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/scanned_barcode_label.dart';

import 'package:mobile_scanner_example/scanner_error_widget.dart';

class BarcodeScannerWithScanWindow extends StatefulWidget {
  const BarcodeScannerWithScanWindow({super.key});

  @override
  State<BarcodeScannerWithScanWindow> createState() =>
      _BarcodeScannerWithScanWindowState();
}

class _BarcodeScannerWithScanWindowState
    extends State<BarcodeScannerWithScanWindow> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
  );

  // TODO: Fix BoxFit.fill & BoxFit.fitHeight
  BoxFit boxFit = BoxFit.contain;
  final double containerWidth = 300;
  final double containerHeight = 600;

  @override
  Widget build(BuildContext context) {
    final scanWindowWidth = containerWidth * 0.8;
    final scanWindowHeight = containerHeight * 0.2;

    final scanWindow = Rect.fromLTWH(
      (containerWidth - scanWindowWidth) / 2,
      (containerHeight - scanWindowHeight) / 3,
      scanWindowWidth,
      scanWindowHeight,
    );

    final Size screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('With Scan window')),
      backgroundColor: Colors.black,
      body: Container(
        height: screenSize.height,
        width: screenSize.width,
        color: Colors.blueGrey,
        child: Stack(
          children: [
            const Text(
              "Background",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Center(
              child: Container(
                width: containerWidth,
                height: containerHeight,
                color: Colors.red,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      fit: boxFit,
                      scanWindow: scanWindow,
                      controller: controller,
                      errorBuilder: (context, error) {
                        return ScannerErrorWidget(error: error);
                      },
                    ),
                    BarcodeOverlay(controller: controller, boxFit: boxFit),
                    ScanWindowOverlay(
                      scanWindow: scanWindow,
                      controller: controller,
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        height: 100,
                        color: const Color.fromRGBO(0, 0, 0, 0.4),
                        child:
                            ScannedBarcodeLabel(barcodes: controller.barcodes),
                      ),
                    ),
                    Text(
                      "Camera preview\nBoxFit: $boxFit",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Positioned(
                      bottom: 100,
                      width: containerWidth,
                      child: Wrap(
                        spacing: 0.5,
                        runSpacing: 3.0,
                        alignment: WrapAlignment.center,
                        children: BoxFitOption.values.map((option) {
                          return SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  boxFit = option.boxFit;
                                });
                              },
                              child: Text(option.label),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }
}

enum BoxFitOption {
  fill(BoxFit.fill, "fill"),
  contain(BoxFit.contain, "contain"),
  cover(BoxFit.cover, "cover"),
  fitWidth(BoxFit.fitWidth, "fitWidth"),
  fitHeight(BoxFit.fitHeight, "fitHeight"),
  none(BoxFit.none, "none"),
  scaleDown(BoxFit.scaleDown, "scaleDown");

  final BoxFit boxFit;
  final String label;

  const BoxFitOption(this.boxFit, this.label);
}
