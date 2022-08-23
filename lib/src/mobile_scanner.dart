import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A widget showing a live camera preview.
class MobileScanner extends StatefulWidget {
  /// The controller of the camera.
  final MobileScannerController? controller;

  /// Function that gets called when a Barcode is detected.
  ///
  /// [barcode] The barcode object with all information about the scanned code.
  /// [arguments] Information about the state of the MobileScanner widget
  final Function(Barcode barcode, MobileScannerArguments? args) onDetect;

  /// TODO: Function that gets called when the Widget is initialized. Can be usefull
  /// to check wether the device has a torch(flash) or not.
  ///
  /// [arguments] Information about the state of the MobileScanner widget
  // final Function(MobileScannerArguments args)? onInitialize;

  /// Handles how the widget should fit the screen.
  final BoxFit fit;

  /// Set to false if you don't want duplicate scans.
  final bool allowDuplicates;

  /// Create a [MobileScanner] with a [controller], the [controller] must has been initialized.
  const MobileScanner({
    super.key,
    required this.onDetect,
    this.controller,
    this.fit = BoxFit.cover,
    this.allowDuplicates = false,
  });

  @override
  State<MobileScanner> createState() => _MobileScannerState();
}

class _MobileScannerState extends State<MobileScanner>
    with WidgetsBindingObserver {
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = widget.controller ?? MobileScannerController();
    if (!controller.isStarting) controller.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!controller.isStarting && controller.autoResume) controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        controller.stop();
        break;
    }
  }

  String? lastScanned;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.arguments,
      builder: (context, value, child) {
        value = value as MobileScannerArguments?;
        if (value == null) {
          return const ColoredBox(color: Colors.black);
        } else {
          controller.barcodes.listen((barcode) {
            if (!widget.allowDuplicates) {
              if (lastScanned != barcode.rawValue) {
                lastScanned = barcode.rawValue;
                widget.onDetect(barcode, value! as MobileScannerArguments);
              }
            } else {
              widget.onDetect(barcode, value! as MobileScannerArguments);
            }
          });
          return ClipRect(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: FittedBox(
                fit: widget.fit,
                child: SizedBox(
                  width: value.size.width,
                  height: value.size.height,
                  child: kIsWeb
                      ? HtmlElementView(viewType: value.webId!)
                      : Texture(textureId: value.textureId!),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    controller.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
