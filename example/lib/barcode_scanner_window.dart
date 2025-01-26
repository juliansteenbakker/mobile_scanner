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
  double containerWidth = 300;
  double containerHeight = 600;

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

    return Scaffold(
      appBar: AppBar(title: const Text('With Scan window')),
      backgroundColor: Colors.black,
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        color: Colors.blueGrey,
        child: Stack(
          children: [
            const Text(
              "Background",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
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
                            horizontal: 16, vertical: 8),
                        height: 100,
                        color: const Color.fromRGBO(0, 0, 0, 0.4),
                        child:
                            ScannedBarcodeLabel(barcodes: controller.barcodes),
                      ),
                    ),
                    const Text(
                      "Camera preview",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold),
                    ),
                    Positioned(
                      bottom: 100,
                      width: containerWidth,
                      child: Wrap(
                        spacing: 0.5,
                        runSpacing: 3.0,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    boxFit = BoxFit.fill;
                                  });
                                },
                                child: const Text("fill"),
                              )),
                          SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    boxFit = BoxFit.contain;
                                  });
                                },
                                child: const Text("contain"),
                              )),
                          SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    boxFit = BoxFit.cover;
                                  });
                                },
                                child: const Text("cover"),
                              )),
                          SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    boxFit = BoxFit.fitWidth;
                                  });
                                },
                                child: const Text("fitWidth"),
                              )),
                          SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    boxFit = BoxFit.fitHeight;
                                  });
                                },
                                child: const Text("fitHeight"),
                              )),
                          SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    boxFit = BoxFit.none;
                                  });
                                },
                                child: const Text("none"),
                              )),
                          SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    boxFit = BoxFit.scaleDown;
                                  });
                                },
                                child: const Text("scaleDown"),
                              )),
                        ],
                      ),
                    )
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
