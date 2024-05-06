import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/scanner_button_widgets.dart';
import 'package:mobile_scanner_example/scanner_error_widget.dart';

class BarcodeScannerListView extends StatefulWidget {
  const BarcodeScannerListView({super.key});

  @override
  State<BarcodeScannerListView> createState() => _BarcodeScannerListViewState();
}

class _BarcodeScannerListViewState extends State<BarcodeScannerListView> {
  final MobileScannerController controller = MobileScannerController(
    torchEnabled: true,
  );

  Widget _buildBarcodesListView() {
    return StreamBuilder<BarcodeCapture>(
      stream: controller.barcodes,
      builder: (context, snapshot) {
        final barcodes = snapshot.data?.barcodes;

        if (barcodes == null || barcodes.isEmpty) {
          return const Center(
            child: Text(
              'Scan Something!',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          );
        }

        return ListView.builder(
          itemCount: barcodes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                barcodes[index].rawValue ?? 'No raw value',
                overflow: TextOverflow.fade,
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('With ListView')),
      backgroundColor: Colors.black,
      body: Stack(
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
              child: Column(
                children: [
                  Expanded(
                    child: _buildBarcodesListView(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ToggleFlashlightButton(controller: controller),
                      StartStopMobileScannerButton(controller: controller),
                      const Spacer(),
                      SwitchCameraButton(controller: controller),
                      AnalyzeImageFromGalleryButton(controller: controller),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }
}
