import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'mobile_scanner_arguments.dart';

enum Ratio {
  ratio_4_3,
  ratio_16_9
}

/// A widget showing a live camera preview.
class MobileScanner extends StatefulWidget {
  /// The controller of the camera.
  final MobileScannerController? controller;
  final Function(Barcode barcode, MobileScannerArguments args)? onDetect;
  final BoxFit fit;

  /// Create a [MobileScanner] with a [controller], the [controller] must has been initialized.
  const MobileScanner(
      {Key? key, this.onDetect, this.controller, this.fit = BoxFit.cover})
      : assert((controller != null  )),  super(key: key);

  @override
  State<MobileScanner> createState() => _MobileScannerState();
}

class _MobileScannerState extends State<MobileScanner>
    with WidgetsBindingObserver {
  bool onScreen = true;
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      controller = MobileScannerController();
    } else {
      controller = widget.controller!;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => onScreen = true);
    } else {
      if (onScreen) {
        controller.stop();
      }
      setState(() {
        onScreen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, BoxConstraints constraints) {
      if (!onScreen) return const Text("Camera Paused.");
      return ValueListenableBuilder(
          valueListenable: controller.args,
          builder: (context, value, child) {
            value = value as MobileScannerArguments?;
            if (value == null) {
              return Container(color: Colors.black);
            } else {
              controller.barcodes.listen(
                  (a) => widget.onDetect!(a, value as MobileScannerArguments));
              debugPrint(' size MediaQuery ${MediaQuery.of(context).size}');
              return ClipRect(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: FittedBox(
                    fit: widget.fit,
                    child: SizedBox(
                      width: value.size.width,
                      height: value.size.height,
                      child: Texture(textureId: value.textureId),
                    ),
                  ),
                ),
              );
            }
          });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}