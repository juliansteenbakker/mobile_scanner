import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/scanner_error_widget.dart';

class BarcodeScannerPageView extends StatefulWidget {
  const BarcodeScannerPageView({super.key});

  @override
  State<BarcodeScannerPageView> createState() => _BarcodeScannerPageViewState();
}

class _BarcodeScannerPageViewState extends State<BarcodeScannerPageView> {
  final MobileScannerController scannerController = MobileScannerController();

  final PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    scannerController.start();
  }

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
          await scannerController.stop();

          // When switching pages, add a delay to the next start call.
          // Otherwise the camera will start before the next page is displayed.
          await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

          if (!mounted) {
            return;
          }

          scannerController.start();
        },
        children: [
          _BarcodeScannerPage(controller: scannerController),
          const SizedBox(),
          _BarcodeScannerPage(controller: scannerController),
          _BarcodeScannerPage(controller: scannerController),
        ],
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await scannerController.dispose();
    pageController.dispose();
    super.dispose();
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
              child: StreamBuilder<BarcodeCapture>(
                stream: controller.barcodes,
                builder: (context, snapshot) {
                  final barcodes = snapshot.data?.barcodes;

                  if (barcodes == null || barcodes.isEmpty) {
                    return const Text(
                      'Scan Something!',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    );
                  }

                  return Text(
                    barcodes.first.rawValue ?? 'No raw value',
                    overflow: TextOverflow.fade,
                    style: const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
