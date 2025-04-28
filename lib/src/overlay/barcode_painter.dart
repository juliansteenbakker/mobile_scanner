import 'package:flutter/material.dart';
class BarcodePainter extends CustomPainter {
  const BarcodePainter({
    required this.boundingBox,
    required this.rotation,
    required this.barcodeValue,
    required this.color,
    required this.textPainter,
    required this.strokeWidth,
  });

  final Rect boundingBox;
  final double rotation;
  final String barcodeValue;
  final Color color;
  final TextPainter textPainter;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Offset center = boundingBox.center;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    final RRect roundedRect = RRect.fromRectAndRadius(
      boundingBox,
      const Radius.circular(12),
    );

    canvas.drawRRect(roundedRect, paint);

    // Draw the barcode value
    final textSpan = TextSpan(
      text: barcodeValue,
      style: TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );

    textPainter.text = textSpan;
    textPainter.layout(maxWidth: boundingBox.width * 0.6);

    final Offset textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );

    final textBgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: textPainter.width * 1.2,
        height: textPainter.height * 1.5,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      textBgRect,
      Paint()..color = Colors.white.withOpacity(0.8),
    );

    textPainter.paint(canvas, textOffset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BarcodePainter oldDelegate) =>
      oldDelegate.boundingBox != boundingBox ||
          oldDelegate.rotation != rotation ||
          oldDelegate.barcodeValue != barcodeValue;
}
