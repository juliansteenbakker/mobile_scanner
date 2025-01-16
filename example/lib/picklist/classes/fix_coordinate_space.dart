import 'package:flutter/services.dart';

Size fixPortraitLandscape(
  Size imageSize,
  DeviceOrientation orientation,
) {
  switch (orientation) {
    case DeviceOrientation.portraitUp:
    case DeviceOrientation.portraitDown:
      return Size(imageSize.shortestSide, imageSize.longestSide);
    case DeviceOrientation.landscapeLeft:
    case DeviceOrientation.landscapeRight:
      return Size(imageSize.longestSide, imageSize.shortestSide);
  }
}

List<Offset> fixCorners(List<Offset> corners) {
  // Clone the original list to avoid side-effects
  final sorted = List<Offset>.from(corners);

  sorted.sort((a, b) {
    // Prioritize y-axis (dy), and within that, the x-axis (dx)
    int compare = a.dy.compareTo(b.dy);
    if (compare == 0) {
      compare = a.dx.compareTo(b.dx);
    }
    return compare;
  });

  final topLeft = sorted.first; // smallest x, smallest y
  final topRight = sorted[1]; // larger x, smaller y
  final bottomLeft = sorted[2]; // smaller x, larger y
  final bottomRight = sorted.last; // larger x, larger y

  return [topLeft, topRight, bottomRight, bottomLeft];
}
