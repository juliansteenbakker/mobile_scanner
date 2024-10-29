import 'package:flutter/material.dart';

class ScannerPainter extends CustomPainter {
  ScannerPainter(this.scanWindow);

  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    // Define the main overlay path covering the entire screen
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Define the cutout path in the center
    final cutoutPath = Path()..addRect(scanWindow);

    // Combine the two paths: overlay minus the cutout area
    final overlayWithCutoutPath =
        Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    // Paint the overlay with the cutout
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5); // Semi-transparent black
    canvas.drawPath(overlayWithCutoutPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
