import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

BarcodeFormat toFormat(int value) {
  switch (value) {
    case 0:
      return BarcodeFormat.all;
    case 1:
      return BarcodeFormat.code128;
    case 2:
      return BarcodeFormat.code39;
    case 4:
      return BarcodeFormat.code93;
    case 8:
      return BarcodeFormat.codebar;
    case 16:
      return BarcodeFormat.dataMatrix;
    case 32:
      return BarcodeFormat.ean13;
    case 64:
      return BarcodeFormat.ean8;
    case 128:
      return BarcodeFormat.itf;
    case 256:
      return BarcodeFormat.qrCode;
    case 512:
      return BarcodeFormat.upcA;
    case 1024:
      return BarcodeFormat.upcE;
    case 2048:
      return BarcodeFormat.pdf417;
    case 4096:
      return BarcodeFormat.aztec;
    default:
      return BarcodeFormat.unknown;
  }
}
