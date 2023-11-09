import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/scanner_button_widgets.dart';
import 'package:mobile_scanner_example/scanner_error_widget.dart';

class BarcodeScannerWithController extends StatefulWidget {
  const BarcodeScannerWithController({super.key});

  @override
  State<BarcodeScannerWithController> createState() =>
      _BarcodeScannerWithControllerState();
}

class _BarcodeScannerWithControllerState
    extends State<BarcodeScannerWithController>
    with SingleTickerProviderStateMixin {
  BarcodeCapture? barcode;

  final MobileScannerController controller = MobileScannerController(
    torchEnabled: true, useNewCameraSelector: true,
    // formats: [BarcodeFormat.qrCode]
    // facing: CameraFacing.front,
    // detectionSpeed: DetectionSpeed.normal
    // detectionTimeoutMs: 1000,
    // returnImage: false,
  );

  StreamSubscription<Object?>? _barcodesSubscription;

  @override
  void initState() {
    super.initState();
    _barcodesSubscription = controller.barcodes.listen((event) {
      if (!context.mounted) {
        return;
      }

      setState(() {
        barcode = event;
      });
    });

    controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('With controller')),
      backgroundColor: Colors.black,
      body: Builder(
        builder: (context) {
          return Stack(
            children: [
              MobileScanner(
                controller: controller,
                errorBuilder: (context, error, child) {
                  return ScannerErrorWidget(error: error);
                },
                fit: BoxFit.contain,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  alignment: Alignment.bottomCenter,
                  height: 100,
                  color: Colors.black.withOpacity(0.4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ToggleFlashlightButton(controller: controller),
                      StartStopMobileScannerButton(controller: controller),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 200,
                          height: 50,
                          child: FittedBox(
                            child: Text(
                              barcode?.barcodes.first.rawValue ??
                                  'Scan something!',
                              overflow: TextOverflow.fade,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      SwitchCameraButton(controller: controller),
                      AnalyzeImageFromGalleryButton(controller: controller),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _barcodesSubscription?.cancel();
    await controller.dispose();
    super.dispose();
  }
}
