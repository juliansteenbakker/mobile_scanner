import 'dart:math' as math;
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

    final ratios = calculateBoxFitRatio(boxFit, cameraPreviewSize, size);
    // final adjustedSize = applyBoxFit(boxFit, cameraPreviewSize, size);

    final double horizontalPadding =
        (cameraPreviewSize.width * ratios.widthRatio - size.width) / 2;
    final double verticalPadding =
        (cameraPreviewSize.height * ratios.heightRatio - size.height) / 2;

    final List<Offset> adjustedOffset = [
      for (final offset in barcodeCorners)
        Offset(
          offset.dx * ratios.widthRatio - horizontalPadding,
          offset.dy * ratios.heightRatio - verticalPadding,
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

/// Calculate the scaling ratios for width and height to fit the small box (cameraPreviewSize)
/// into the large box (size) based on the specified BoxFit mode.
/// Returns a record containing the width and height scaling ratios.
({double widthRatio, double heightRatio}) calculateBoxFitRatio(
    BoxFit boxFit, Size cameraPreviewSize, Size size) {
  // If the width or height of cameraPreviewSize or size is 0, return (1.0, 1.0) (no scaling)
  if (cameraPreviewSize.width <= 0 ||
      cameraPreviewSize.height <= 0 ||
      size.width <= 0 ||
      size.height <= 0) {
    return (widthRatio: 1.0, heightRatio: 1.0);
  }

  // Calculate the scaling ratios for width and height
  final widthRatio = size.width / cameraPreviewSize.width;
  final heightRatio = size.height / cameraPreviewSize.height;

  switch (boxFit) {
    case BoxFit.fill:
      // Stretch to fill the large box without maintaining aspect ratio
      return (widthRatio: widthRatio, heightRatio: heightRatio);

    case BoxFit.contain:
      // Maintain aspect ratio, ensure the content fits entirely within the large box
      final ratio = math.min(widthRatio, heightRatio);
      return (widthRatio: ratio, heightRatio: ratio);

    case BoxFit.cover:
      // Maintain aspect ratio, ensure the content fully covers the large box
      final ratio = math.max(widthRatio, heightRatio);
      return (widthRatio: ratio, heightRatio: ratio);

    case BoxFit.fitWidth:
      // Maintain aspect ratio, ensure the width matches the large box
      return (widthRatio: widthRatio, heightRatio: widthRatio);

    case BoxFit.fitHeight:
      // Maintain aspect ratio, ensure the height matches the large box
      return (widthRatio: heightRatio, heightRatio: heightRatio);

    case BoxFit.none:
      // No scaling
      return (widthRatio: 1.0, heightRatio: 1.0);

    case BoxFit.scaleDown:
      // If the content is larger than the large box, scale down to fit; otherwise, no scaling
      final ratio = math.min(1.0, math.min(widthRatio, heightRatio));
      return (widthRatio: ratio, heightRatio: ratio);
  }
}
