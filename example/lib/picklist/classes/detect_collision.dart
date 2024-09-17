//Some magic created by chatGPT

import 'package:flutter/material.dart';

bool isOffsetInsideShape(Offset point, List<Offset> shape) {
  return _isPointInPolygon(shape, point);
}

bool _isPointInPolygon(List<Offset> polygon, Offset point) {
  // Use the ray-casting algorithm for checking if a point is inside a polygon
  bool inside = false;
  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
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

// import 'package:flutter/material.dart';
//
// bool crosshairFullyFitsIntoShape(Rect rect, List<Offset> shape) {
//   final List<Offset> rectCorners = [
//     Offset(rect.left, rect.top),
//     Offset(rect.right, rect.top),
//     Offset(rect.right, rect.bottom),
//     Offset(rect.left, rect.bottom),
//   ];
//
//   // Check if all rect corners are inside the shape
//   for (final Offset corner in rectCorners) {
//     if (!_isPointInPolygon(shape, corner)) {
//       return false; // If any corner is outside, the rectangle doesn't fit fully
//     }
//   }
//
//   return true; // All corners are inside the shape
// }
//
// bool _isPointInPolygon(List<Offset> polygon, Offset point) {
//   // Use the ray-casting algorithm for checking if a point is inside a polygon
//   bool inside = false;
//   for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
//     if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
//         (point.dx <
//             (polygon[j].dx - polygon[i].dx) *
//                     (point.dy - polygon[i].dy) /
//                     (polygon[j].dy - polygon[i].dy) +
//                 polygon[i].dx)) {
//       inside = !inside;
//     }
//   }
//   return inside;
// }
// // import 'package:flutter/material.dart';
// //
// // bool crosshairTouchesBarcode(Rect rect, List<Offset> shape) {
// //   final List<Offset> rectCorners = [
// //     Offset(rect.left, rect.top),
// //     Offset(rect.right, rect.top),
// //     Offset(rect.right, rect.bottom),
// //     Offset(rect.left, rect.bottom),
// //   ];
// //   final List<Offset> edges = [shape[0], shape[1], shape[2], shape[3], shape[0]];
// //
// //   // Check edge intersection
// //   for (int i = 0; i < edges.length - 1; i++) {
// //     for (int j = 0; j < rectCorners.length; j++) {
// //       final int next = (j + 1) % rectCorners.length;
// //       if (_checkIntersection(
// //         edges[i],
// //         edges[i + 1],
// //         rectCorners[j],
// //         rectCorners[next],
// //       )) {
// //         return true;
// //       }
// //     }
// //   }
// //
// //   // Check if any rect corner is inside the shape
// //   for (final Offset corner in rectCorners) {
// //     if (_isPointInPolygon(shape, corner)) {
// //       return true;
// //     }
// //   }
// //
// //   return false;
// // }
// //
// // bool _checkIntersection(Offset p1, Offset p2, Offset p3, Offset p4) {
// //   // Calculate the intersection of two line segments
// //   double s1X;
// //   double s1Y;
// //   double s2X;
// //   double s2Y;
// //   s1X = p2.dx - p1.dx;
// //   s1Y = p2.dy - p1.dy;
// //   s2X = p4.dx - p3.dx;
// //   s2Y = p4.dy - p3.dy;
// //
// //   double s;
// //   double t;
// //   s = (-s1Y * (p1.dx - p3.dx) + s1X * (p1.dy - p3.dy)) /
// //       (-s2X * s1Y + s1X * s2Y);
// //   t = (s2X * (p1.dy - p3.dy) - s2Y * (p1.dx - p3.dx)) /
// //       (-s2X * s1Y + s1X * s2Y);
// //
// //   return s >= 0 && s <= 1 && t >= 0 && t <= 1;
// // }
// //
// // bool _isPointInPolygon(List<Offset> polygon, Offset point) {
// //   // Ray-casting algorithm for checking if a point is inside a polygon
// //   bool inside = false;
// //   for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
// //     if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
// //         (point.dx <
// //             (polygon[j].dx - polygon[i].dx) *
// //                     (point.dy - polygon[i].dy) /
// //                     (polygon[j].dy - polygon[i].dy) +
// //                 polygon[i].dx)) {
// //       inside = !inside;
// //     }
// //   }
// //   return inside;
// // }
