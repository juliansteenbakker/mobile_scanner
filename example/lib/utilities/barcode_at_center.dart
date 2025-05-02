import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// This function finds the barcode that touches the center of the
/// image. If no barcode is found that touches the center, null is returned.
/// See `_BarcodeScannerPicklistState` and the returnImage option for more info.
///
/// https://github.com/juliansteenbakker/mobile_scanner/issues/1183
Barcode? findBarcodeAtCenter(
  BarcodeCapture barcodeCapture,
  DeviceOrientation orientation,
) {
  final Size imageSize = _fixPortraitLandscape(
    barcodeCapture.size,
    orientation,
  );
  for (final Barcode barcode in barcodeCapture.barcodes) {
    final List<Offset> corners = _fixCorners(barcode.corners);
    if (_isPolygonTouchingTheCenter(imageSize: imageSize, polygon: corners)) {
      return barcode;
    }
  }
  return null;
}

/// Check if the polygon, represented by a list of offsets, touches the center
/// of an image when the size of the image is given.
bool _isPolygonTouchingTheCenter({
  required Size imageSize,
  required List<Offset> polygon,
}) {
  final centerOfCameraOutput = Offset(
    imageSize.width / 2,
    imageSize.height / 2,
  );
  return _isPointInPolygon(point: centerOfCameraOutput, polygon: polygon);
}

/// Credits to chatGPT:
/// Checks if a given [point] is inside the [polygon] boundaries.
///
/// Parameters:
///   - [point]: The `Offset` (usually represents a point in 2D space) to check.
///   - [polygon]: A List of `Offset` representing the vertices of the polygon.
///
/// Returns:
///   - A boolean value: `true` if the point is inside the polygon, or `false`
///   otherwise.
///
/// Uses the ray-casting algorithm based on the Jordan curve theorem.
bool _isPointInPolygon({required Offset point, required List<Offset> polygon}) {
  // Initial variables:
  int i; // Loop variable for current vertex
  int j =
      polygon.length -
      1; // Last vertex index, initialized to the last vertex of the polygon
  var inside = false; // Boolean flag initialized to false

  // Loop through each edge of the polygon
  for (i = 0; i < polygon.length; j = i++) {
    // Check if point's y-coordinate is within the y-boundaries of the edge
    if (((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy)) &&
        // Check if the point's x-coordinate is to the left of the edge
        (point.dx <
            (polygon[j].dx - polygon[i].dx) *
                    // Horizontal distance between the vertices of the edge
                    (point.dy - polygon[i].dy) /
                    // Scale factor based on the y-distance of the point to the
                    // lower vertex
                    (polygon[j].dy - polygon[i].dy) +
                // Vertical distance between the vertices of the edge
                polygon[i].dx)) {
      // Horizontal position of the lower vertex
      // If the ray intersects the polygon edge, invert the inside flag
      inside = !inside;
    }
  }
  // Return the status of the inside flag which tells if the point is inside the
  // polygon or not
  return inside;
}

Size _fixPortraitLandscape(Size imageSize, DeviceOrientation orientation) {
  switch (orientation) {
    case DeviceOrientation.portraitUp:
    case DeviceOrientation.portraitDown:
      return Size(imageSize.shortestSide, imageSize.longestSide);
    case DeviceOrientation.landscapeLeft:
    case DeviceOrientation.landscapeRight:
      return Size(imageSize.longestSide, imageSize.shortestSide);
  }
}

List<Offset> _fixCorners(List<Offset> corners) {
  // Clone the original list to avoid side-effects
  final sorted = List<Offset>.from(corners)..sort((a, b) {
    // Prioritize y-axis (dy), and within that, the x-axis (dx)
    int compare = a.dy.compareTo(b.dy);
    if (compare == 0) {
      compare = a.dx.compareTo(b.dx);
    }
    return compare;
  });

  final Offset topLeft = sorted.first; // smallest x, smallest y
  final Offset topRight = sorted[1]; // larger x, smaller y
  final Offset bottomLeft = sorted[2]; // smaller x, larger y
  final Offset bottomRight = sorted.last; // larger x, larger y

  return [topLeft, topRight, bottomRight, bottomLeft];
}
