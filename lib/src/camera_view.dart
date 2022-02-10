import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'camera_args.dart';
import 'camera_controller.dart';

/// A widget showing a live camera preview.
class CameraView extends StatelessWidget {
  /// The controller of the camera.
  final CameraController controller;
  final Function(Barcode barcode, CameraArgs args)? onDetect;

  /// Create a [CameraView] with a [controller], the [controller] must has been initialized.
  CameraView(this.controller, {this.onDetect});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.args,
      builder: (context, value, child) => _build(context, value as CameraArgs?),
    );
  }

  Widget _build(BuildContext context, CameraArgs? value) {
    if (value == null) {
      return Container(color: Colors.black);
    } else {

      controller.barcodes.listen((a) => onDetect!(a, value));

      return ClipRect(
        child: Transform.scale(
          scale: value.size.fill(MediaQuery.of(context) .size),
          child: Center(
            child: AspectRatio(
              aspectRatio: value.size.aspectRatio,
              child: Texture(textureId: value.textureId),
            ),
          ),
        ),
      );
    }
  }
}

extension on Size {
  double fill(Size targetSize) {
    if (targetSize.aspectRatio < aspectRatio) {
      return targetSize.height * aspectRatio / targetSize.width;
    } else {
      return targetSize.width / aspectRatio / targetSize.height;
    }
  }
}
