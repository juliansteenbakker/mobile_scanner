import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// This class represents a [CustomPainter] that draws the [barcodeCorners] of a single barcode.
class BarcodePainter extends CustomPainter {
  /// Construct a new [BarcodePainter] instance.
  const BarcodePainter({
    required this.barcodeCorners,
    required this.barcodeSize,
    required this.boxFit,
    required this.cameraPreviewSize,
    required this.color,
    required this.style,
  });

  /// The corners of the barcode.
  final List<Offset> barcodeCorners;

  /// The size of the barcode.
  final Size barcodeSize;

  /// The [BoxFit] to use when painting the barcode box.
  final BoxFit boxFit;

  /// The size of the camera preview,
  /// relative to which the [barcodeSize] and [barcodeCorners] are positioned.
  final Size cameraPreviewSize;

  /// The color to use when painting the barcode box.
  final Color color;

  /// The style to use when painting the barcode box.
  final PaintingStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (barcodeCorners.isEmpty ||
        barcodeSize.isEmpty ||
        cameraPreviewSize.isEmpty) {
      return;
    }

    final adjustedSize = applyBoxFit(boxFit, cameraPreviewSize, size);

    double verticalPadding = size.height - adjustedSize.destination.height;
    double horizontalPadding = size.width - adjustedSize.destination.width;
    if (verticalPadding > 0) {
      verticalPadding = verticalPadding / 2;
    } else {
      verticalPadding = 0;
    }

    if (horizontalPadding > 0) {
      horizontalPadding = horizontalPadding / 2;
    } else {
      horizontalPadding = 0;
    }

    final double ratioWidth =
        cameraPreviewSize.width / adjustedSize.destination.width;
    final double ratioHeight =
        cameraPreviewSize.height / adjustedSize.destination.height;

    final List<Offset> adjustedOffset = [
      for (final offset in barcodeCorners)
        Offset(
          offset.dx / ratioWidth + horizontalPadding,
          offset.dy / ratioHeight + verticalPadding,
        ),
    ];

    final cutoutPath = Path()..addPolygon(adjustedOffset, true);

    final backgroundPaint = Paint()
      ..color = color
      ..style = style;

    canvas.drawPath(cutoutPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(BarcodePainter oldDelegate) {
    const ListEquality<Offset> listEquality = ListEquality<Offset>();

    return listEquality.equals(oldDelegate.barcodeCorners, barcodeCorners) ||
        oldDelegate.barcodeSize != barcodeSize ||
        oldDelegate.boxFit != boxFit ||
        oldDelegate.cameraPreviewSize != cameraPreviewSize ||
        oldDelegate.color != color ||
        oldDelegate.style != style;
  }
}
