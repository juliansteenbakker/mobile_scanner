import 'package:flutter/material.dart';

/// Camera args for [CameraView].
class MobileScannerArguments {
  /// The texture id.
  final int textureId;

  /// Size of the texture.
  final Size size;

  final bool hasTorch;

  /// Create a [MobileScannerArguments].
  MobileScannerArguments(
      {required this.textureId, required this.size, required this.hasTorch});
}
