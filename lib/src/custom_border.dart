import 'package:flutter/material.dart';

class BorderPainter extends CustomPainter {
  BorderPainter({
    required this.strokeWidth,
    required this.boxWidth,
    required this.boxHeight,
    required this.strokeColor,
    required this.cornerSide,
  });

  final double strokeWidth;
  final double boxWidth;
  final double boxHeight;
  final Color strokeColor;
  final double cornerSide;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..filterQuality = FilterQuality.high
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(cornerSide, 0)
      ..quadraticBezierTo(0, 0, 0, cornerSide)
      ..moveTo(0, boxHeight - cornerSide)
      ..quadraticBezierTo(0, boxHeight, cornerSide, boxHeight)
      ..moveTo(boxWidth - cornerSide, boxHeight)
      ..quadraticBezierTo(boxWidth, boxHeight, boxWidth, boxHeight - cornerSide)
      ..moveTo(boxWidth, cornerSide)
      ..quadraticBezierTo(boxWidth, 0, boxWidth - cornerSide, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BorderPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(BorderPainter oldDelegate) => false;
}
