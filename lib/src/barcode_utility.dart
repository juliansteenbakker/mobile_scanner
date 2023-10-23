import 'package:flutter/material.dart';

List<Offset>? toCorners(List<Map<Object?, Object?>>? data) {
  if (data == null) {
    return null;
  }

  return List.unmodifiable(
    data.map((Map<Object?, Object?> e) {
      return Offset(e['x']! as double, e['y']! as double);
    }),
  );
}
