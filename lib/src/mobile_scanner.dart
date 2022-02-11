import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'mobile_scanner_arguments.dart';

/// A widget showing a live camera preview.
class MobileScanner extends StatefulWidget {
  /// The controller of the camera.
  final MobileScannerController? controller;
  final Function(Barcode barcode, MobileScannerArguments args)? onDetect;
  final bool fitScreen;
  final bool fitWidth;

  /// Create a [MobileScanner] with a [controller], the [controller] must has been initialized.
  const MobileScanner(
      {Key? key, this.onDetect, this.controller, this.fitScreen = true, this.fitWidth = true})
      : super(key: key);

  @override
  State<MobileScanner> createState() => _MobileScannerState();
}

class _MobileScannerState extends State<MobileScanner>
    with WidgetsBindingObserver {
  bool onScreen = true;
  MobileScannerController? controller;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => onScreen = true);
    } else {
      if (controller != null && onScreen) {
        controller!.stop();
      }
      setState(() {
        onScreen = false;
        controller = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, BoxConstraints constraints) {
      final media = MediaQuery.of(context);

      controller ??= MobileScannerController(context,
          width: constraints.maxWidth, height: constraints.maxHeight);
      if (!onScreen) return const Text("Camera Paused.");
      return ValueListenableBuilder(
          valueListenable: controller!.args,
          builder: (context, value, child) {
            value = value as MobileScannerArguments?;
            if (value == null) {
              return Container(color: Colors.black);
            } else {
              controller!.barcodes.listen(
                  (a) => widget.onDetect!(a, value as MobileScannerArguments));
              // Texture(textureId: value.textureId)
              return ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: value.size.width,
                    height: value.size.height,
                    child: Texture(textureId: value.textureId),
                  ),
                ),
              );
            }
          });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
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
