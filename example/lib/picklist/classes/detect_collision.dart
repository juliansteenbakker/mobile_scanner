import 'package:flutter/material.dart';

bool isPointInPolygon(Offset point, List<Offset> polygon) {
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
