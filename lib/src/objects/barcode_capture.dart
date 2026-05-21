/// @docImport 'package:mobile_scanner/src/mobile_scanner_controller.dart';
library;

import 'dart:typed_data';
import 'dart:ui';

import 'package:mobile_scanner/src/objects/barcode.dart';

/// This class represents a scanned barcode.
class BarcodeCapture {
  /// Create a new [BarcodeCapture] instance.
  const BarcodeCapture({
    this.barcodes = const <Barcode>[],
    this.image,
    this.raw,
    this.size = Size.zero,
  });

  /// The list of scanned barcodes.
  final List<Barcode> barcodes;

  /// The input image of the barcode capture.
  ///
  /// This is the image that was used to detect the available [barcodes],
  /// not the image from a specific barcode.
  ///
  /// This is always null if [MobileScannerController.returnImage] is false.
  final Uint8List? image;

  /// The raw data of the barcode scan.
  ///
  /// This is the data that was used to detect the available [barcodes], the
  /// input [image] and the [size].
  final Object? raw;

  /// The raw size of the camera input [image],
  /// in which the [barcodes] were detected.
  ///
  /// For example if the camera resolution is 1920x1080 pixels,
  /// this will be a [Size] with a width of 1920 and a height of 1080.
  final Size size;

  /// Returns a copy of this [BarcodeCapture] with the given fields replaced.
  BarcodeCapture copyWith({
    List<Barcode>? barcodes,
    Uint8List? image,
    Object? raw,
    Size? size,
  }) {
    return BarcodeCapture(
      barcodes: barcodes ?? this.barcodes,
      image: image ?? this.image,
      raw: raw ?? this.raw,
      size: size ?? this.size,
    );
  }

  /// Returns a copy of this capture with only the [barcodes] whose
  /// `rawValue.length` is contained in [allowedLengths].
  ///
  /// Returns this capture unchanged when [allowedLengths] is empty: no
  /// filtering is applied.
  /// Returns `null` when [allowedLengths] is non-empty and every barcode is
  /// dropped, so the caller can suppress the capture event entirely.
  ///
  /// Barcodes whose [Barcode.rawValue] is null are dropped when
  /// [allowedLengths] is non-empty, because their length cannot be validated.
  BarcodeCapture? filterByAllowedLengths(Set<int> allowedLengths) {
    if (allowedLengths.isEmpty) {
      return this;
    }

    final filtered = <Barcode>[
      for (final barcode in barcodes)
        if (barcode.rawValue case final rawValue?
            when allowedLengths.contains(rawValue.length))
          barcode,
    ];

    if (filtered.isEmpty) {
      return null;
    }

    if (filtered.length == barcodes.length) {
      return this;
    }

    return copyWith(barcodes: filtered);
  }
}
