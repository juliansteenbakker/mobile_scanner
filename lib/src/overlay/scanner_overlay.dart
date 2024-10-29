import 'package:flutter/material.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/overlay/scanner_painter.dart';

class ScannerOverlay extends StatelessWidget {
  final MobileScannerController controller;
  final Rect scanWindow;

  const ScannerOverlay({
    super.key,
    required this.controller,
    required this.scanWindow,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        // Not ready.
        if (!value.isInitialized ||
            !value.isRunning ||
            value.error != null ||
            value.size.isEmpty) {
          return const SizedBox();
        }

        return CustomPaint(
          size: value.size,
          painter: ScannerPainter(scanWindow),
        );
      },
    );
  }
}
