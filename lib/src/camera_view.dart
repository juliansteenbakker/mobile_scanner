import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'camera_args.dart';

/// A widget showing a live camera preview.
class CameraView extends StatefulWidget {
  /// The controller of the camera.
  final CameraController? controller;
  final Function(Barcode barcode, CameraArgs args)? onDetect;

  /// Create a [CameraView] with a [controller], the [controller] must has been initialized.
  const CameraView({Key? key, this.onDetect, this.controller}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {

  late CameraController controller;
  @override
  initState() {
    super.initState();
    controller = widget.controller ?? CameraController();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: controller.args,
        builder: (context, value, child) {
          value = value as CameraArgs?;
          if (value == null) {
            return Container(color: Colors.black);
          } else {
            controller.barcodes
                .listen((a) => widget.onDetect!(a, value as CameraArgs));

            return ClipRect(
              child: Transform.scale(
                scale: value.size.fill(MediaQuery.of(context).size),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: value.size.aspectRatio,
                    child: Texture(textureId: value.textureId),
                  ),
                ),
              ),
            );
          }
        });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
