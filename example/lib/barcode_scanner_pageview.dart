import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/scanned_barcode_label.dart';
import 'package:mobile_scanner_example/scanner_error_widget.dart';

class BarcodeScannerPageView extends StatefulWidget {
  const BarcodeScannerPageView({super.key});

  @override
  State<BarcodeScannerPageView> createState() => _BarcodeScannerPageViewState();
}

class _BarcodeScannerPageViewState extends State<BarcodeScannerPageView> {
  final MobileScannerController controller = MobileScannerController();

  final PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('With PageView')),
      backgroundColor: Colors.black,
      body: PageView(
        controller: pageController,
        onPageChanged: (index) async {
          // Stop the camera view for the current page,
          // and then restart the camera for the new page.
          await controller.stop();

          // When switching pages, add a delay to the next start call.
          // Otherwise the camera will start before the next page is displayed.
          await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

          if (!mounted) {
            return;
          }

          unawaited(controller.start());
        },
        children: [
          _BarcodeScannerPage(controller: controller),
          const SizedBox(),
          _BarcodeScannerPage(controller: controller),
          _BarcodeScannerPage(controller: controller),
        ],
      ),
    );
  }

  @override
  Future<void> dispose() async {
    pageController.dispose();
    super.dispose();
    await controller.dispose();
  }
}

class _BarcodeScannerPage extends StatelessWidget {
  const _BarcodeScannerPage({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          fit: BoxFit.contain,
          errorBuilder: (context, error, child) {
            return ScannerErrorWidget(error: error);
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            alignment: Alignment.bottomCenter,
            height: 100,
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: ScannedBarcodeLabel(barcodes: controller.barcodes),
            ),
          ),
        ),
      ],
    );
  }
}
