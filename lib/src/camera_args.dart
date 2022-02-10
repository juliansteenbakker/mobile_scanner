import 'package:flutter/material.dart';

/// Camera args for [CameraView].
class CameraArgs {
  /// The texture id.
  final int textureId;

  /// Size of the texture.
  final Size size;

  /// Create a [CameraArgs].
  CameraArgs(this.textureId, this.size);
}
