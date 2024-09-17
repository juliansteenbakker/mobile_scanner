import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

bool isBarcodeAtCenterOfImage({
  required Size cameraOutputSize,
  required Barcode barcode,
}) {
  final centerOfCameraOutput = Offset(
    cameraOutputSize.width / 2,
    cameraOutputSize.height / 2,
  );
  debugPrint(cameraOutputSize.toString());
  return _isPointInPolygon(
    point: centerOfCameraOutput,
    polygon: barcode.corners,
  );
}

//This is what chatGPT came up with.
//https://en.wikipedia.org/wiki/Point_in_polygon
bool _isPointInPolygon({
  required Offset point,
  required List<Offset> polygon,
}) {
  int i;
  int j = polygon.length - 1;
  bool inside = false;

  for (i = 0; i < polygon.length; j = i++) {
    if (((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy)) &&
        (point.dx <
            (polygon[j].dx - polygon[i].dx) *
                    (point.dy - polygon[i].dy) /
                    (polygon[j].dy - polygon[i].dy) +
                polygon[i].dx)) {
      inside = !inside;
    }
  }
  return inside;
}
