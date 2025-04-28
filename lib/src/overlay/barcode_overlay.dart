import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// This widget represents an overlay that paints the bounding boxes of detected
/// barcodes.
class BarcodeOverlay extends StatefulWidget {
  /// Construct a new [BarcodeOverlay] instance.
  const BarcodeOverlay({
    required this.boxFit,
    required this.controller,
    super.key,
    this.color = const Color(0x4DF44336),
    this.style = PaintingStyle.fill,
  });

  /// The [BoxFit] to use when painting the barcode box.
  final BoxFit boxFit;

  /// The controller that provides the barcodes to display.
  final MobileScannerController controller;

  /// The color to use when painting the barcode box.
  ///
  /// Defaults to [Colors.red], with an opacity of 30%.
  final Color color;

  /// The style to use when painting the barcode box.
  ///
  /// Defaults to [PaintingStyle.fill].
  final PaintingStyle style;

  @override
  State<BarcodeOverlay> createState() => _BarcodeOverlayState();
}

class _BarcodeOverlayState extends State<BarcodeOverlay> {
  final _textPainter = TextPainter(
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  );

  @override
  void dispose() {
    _textPainter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetSize = Size(constraints.maxWidth, constraints.maxHeight);


        return ValueListenableBuilder(
          valueListenable: widget.controller,
          builder: (context, value, child) {
            // Not ready.
            if (!value.isInitialized || !value.isRunning || value.error != null) {
              return const SizedBox();
            }

            return StreamBuilder<BarcodeCapture>(
              stream: widget.controller.barcodes,
              builder: (context, snapshot) {
                final BarcodeCapture? barcodeCapture = snapshot.data;

                // No barcode or preview size.
                if (barcodeCapture == null ||
                    barcodeCapture.size.isEmpty ||
                    barcodeCapture.barcodes.isEmpty) {
                  return const SizedBox();
                }


                final overlays = <Widget>[];

                for (final Barcode barcode in barcodeCapture.barcodes) {
                  if (barcode.size.isEmpty || barcode.corners.isEmpty) {
                    continue;
                  }




                  List<Offset> cornersToUse = defaultTargetPlatform == TargetPlatform.android ? sortCorners(barcode.corners) : barcode.corners;

                  // final secondCorner = barcode.corners[1].dx;
                  // final firstCorner = barcode.corners.first.dx;
                  //
                  // if ((secondCorner - firstCorner).abs() > 100) {
                  //   cornersToUse = <Offset>[barcode.corners.first, barcode.corners[3], barcode.corners[2], barcode.corners[1]];
                  // }

                  overlays.add(AnimatedBarcodePainterWrapper(
                      corners: transformCorners(
                        corners: cornersToUse,
                        previewSize: barcodeCapture.size,
                        widgetSize: widgetSize,
                        boxFit: widget.boxFit,
                      ),
                      barcodeValue: barcode.rawValue ?? '',
                      color: widget.color,
                      textPainter: _textPainter,
                    ));
                }

                return Stack(fit: StackFit.expand, children: overlays);
              },
            );
          },
        );
      },
    );
  }
}

List<Offset> sortCorners(List<Offset> originalPoints) {
  final points = List<Offset>.from(originalPoints);
  if (points.length != 4) throw Exception('Exactly 4 points required');

  // Step 1: Sort by y-coordinate (dy) to separate top and bottom
  points.sort((a, b) => a.dy.compareTo(b.dy));

  // Step 2: Take top 2 and bottom 2
  List<Offset> top = points.sublist(0, 2);
  List<Offset> bottom = points.sublist(2, 4);

  // Step 3: Sort top points by x to get topLeft and topRight
  top.sort((a, b) => a.dx.compareTo(b.dx));
  Offset topLeft = top[0];
  Offset topRight = top[1];

  // Step 4: Sort bottom points by x to get bottomLeft and bottomRight
  bottom.sort((a, b) => a.dx.compareTo(b.dx));
  Offset bottomLeft = bottom[0];
  Offset bottomRight = bottom[1];

  return [topLeft, topRight, bottomRight, bottomLeft];
}



class AnimatedBarcodePainterWrapper extends ImplicitlyAnimatedWidget {
  const AnimatedBarcodePainterWrapper({
    super.key,
    required this.corners,
    required this.barcodeValue,
    required this.color,
    required this.textPainter,
    this.strokeWidth = 4.0,
    this.duration = const Duration(milliseconds: 300),
  }) : super(duration: duration);

  final List<Offset> corners;
  final String barcodeValue;
  final Color color;
  final TextPainter textPainter;
  final double strokeWidth;
  final Duration duration;

  @override
  AnimatedWidgetBaseState<AnimatedBarcodePainterWrapper> createState() =>
      _AnimatedBarcodePainterWrapperState();
}

class _AnimatedBarcodePainterWrapperState
    extends AnimatedWidgetBaseState<AnimatedBarcodePainterWrapper> {
  RectTween? _rectTween;
  Tween<double>? _rotationTween;

  @override
  void initState() {
    super.initState();
    final initialAngle = _computeRotation(widget.corners);
    final initialRect = _fitBoundingBox(widget.corners, initialAngle);
    _rectTween = RectTween(begin: initialRect, end: initialRect);
    _rotationTween = Tween<double>(begin: initialAngle, end: initialAngle);
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {

    final newAngle = _computeRotation(widget.corners);
    final newRect = _fitBoundingBox(widget.corners, newAngle);
    if (_rectTween == null) return;

    _rectTween = visitor(
      _rectTween,
      newRect,
          (dynamic value) => RectTween(begin: value as Rect),
    ) as RectTween;

    _rotationTween = visitor(
      _rotationTween,
      newAngle,
          (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BarcodePainter(
        boundingBox: _rectTween!.evaluate(animation)!,
        rotation: _rotationTween!.evaluate(animation)!,
        barcodeValue: widget.barcodeValue,
        color: widget.color,
        textPainter: widget.textPainter,
        strokeWidth: widget.strokeWidth,
      ),
    );
  }
}

double _computeRotation(List<Offset> corners) {
  if (corners.length >= 2) {
    final dx = corners[1].dx - corners[0].dx;
    final dy = corners[1].dy - corners[0].dy;
    return math.atan2(dy, dx);
  }
  return 0.0;
}

Rect _fitBoundingBox(List<Offset> corners, double rotationAngle) {
  final center = corners.fold<Offset>(
      Offset.zero, (sum, c) => sum + c) / corners.length.toDouble();

  // Rotate points into axis-aligned
  List<Offset> rotated = corners.map((point) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    final x = dx * math.cos(-rotationAngle) - dy * math.sin(-rotationAngle);
    final y = dx * math.sin(-rotationAngle) + dy * math.cos(-rotationAngle);
    return Offset(x, y);
  }).toList();

  // Find bounds of rotated points
  final xs = rotated.map((p) => p.dx);
  final ys = rotated.map((p) => p.dy);
  final rect = Rect.fromLTRB(
    xs.reduce(math.min),
    ys.reduce(math.min),
    xs.reduce(math.max),
    ys.reduce(math.max),
  );

  // Return this rect translated back to original space
  return rect.shift(center);
}

List<Offset> transformCorners({
  required List<Offset> corners,
  required Size previewSize,
  required Size widgetSize,
  required BoxFit boxFit,
}) {
  final double previewAspect = previewSize.width / previewSize.height;
  final double widgetAspect = widgetSize.width / widgetSize.height;

  double scaleX, scaleY;
  double dx = 0, dy = 0;

  switch (boxFit) {
    case BoxFit.contain:
      if (widgetAspect > previewAspect) {
        scaleY = widgetSize.height;
        scaleX = widgetSize.height * previewAspect;
        dx = (widgetSize.width - scaleX) / 2;
        dy = 0;
      } else {
        scaleX = widgetSize.width;
        scaleY = widgetSize.width / previewAspect;
        dx = 0;
        dy = (widgetSize.height - scaleY) / 2;
      }
      break;

    case BoxFit.cover:
      if (widgetAspect > previewAspect) {
        scaleX = widgetSize.width;
        scaleY = widgetSize.width / previewAspect;
        dx = 0;
        dy = (widgetSize.height - scaleY) / 2;
      } else {
        scaleY = widgetSize.height;
        scaleX = widgetSize.height * previewAspect;
        dx = (widgetSize.width - scaleX) / 2;
        dy = 0;
      }
      break;

    default:
      scaleX = widgetSize.width;
      scaleY = widgetSize.height;
      break;
  }

  return corners.map((offset) {
    final scaledX = offset.dx * scaleX / previewSize.width + dx;
    final scaledY = offset.dy * scaleY / previewSize.height + dy;
    return Offset(scaledX, scaledY);
  }).toList();
}
