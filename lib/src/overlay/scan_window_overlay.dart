import 'package:flutter/material.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/overlay/scan_window_painter.dart';

/// This widget represents an overlay that paints a scan window cutout.
class ScanWindowOverlay extends StatelessWidget {
  /// Construct a new [ScanWindowOverlay] instance.
  const ScanWindowOverlay({
    super.key,
    required this.controller,
    required this.scanWindow,
    this.color = const Color(0x80000000),
  });

  /// The color for the scan window box.
  ///
  /// Defaults to [Colors.black] with 50% opacity.
  final Color color;

  /// The controller that manages the camera preview.
  final MobileScannerController controller;

  /// The scan window for the overlay.
  final Rect scanWindow;

  @override
  Widget build(BuildContext context) {
    if (scanWindow.isEmpty || scanWindow.isInfinite) {
      return const SizedBox();
    }

    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        // Not ready.
        if (!value.isInitialized || !value.isRunning || value.error != null || value.size.isEmpty) {
          return const SizedBox();
        }

        return CustomPaint(
          size: value.size,
          painter: ScanWindowPainter(
            scanWindow: scanWindow,
            color: color,
          ),
        );
      },
    );
  }
}
