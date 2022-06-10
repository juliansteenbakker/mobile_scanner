import 'package:flutter/material.dart';

/// Camera args for [CameraView].
class MobileScannerArguments {
  /// Create a [MobileScannerArguments].
  MobileScannerArguments({
    this.textureId,
    required this.size,
    required this.hasTorch,
    this.webId,
  });

  /// The texture id.
  final int? textureId;

  /// Size of the texture.
  final Size size;

  final bool hasTorch;

  final String? webId;
}
