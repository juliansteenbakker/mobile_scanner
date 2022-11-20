import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/mobile_scanner_arguments.dart';

typedef MobileScannerCallback = void Function(BarcodeCapture barcodes);
typedef MobileScannerArgumentsCallback = void Function(
  MobileScannerArguments? arguments,
);

/// A widget showing a live camera preview.
class MobileScanner extends StatefulWidget {
  /// The controller that manages the barcode scanner.
  final MobileScannerController controller;

  /// Function that gets called when a Barcode is detected.
  ///
  /// [barcode] The barcode object with all information about the scanned code.
  /// [startInternalArguments] Information about the state of the MobileScanner widget
  final MobileScannerCallback onDetect;

  /// Function that gets called when the scanner is started.
  ///
  /// [arguments] The start arguments of the scanner. This contains the size of
  /// the scanner which can be used to draw a box over the scanner.
  final MobileScannerArgumentsCallback? onStart;

  /// Handles how the widget should fit the screen.
  final BoxFit fit;

  /// Whether to automatically resume the camera when the application is resumed
  final bool autoResume;

  /// Create a [MobileScanner] with a [controller].
  /// The [controller] must have been initialized, using [MobileScannerController.start].
  const MobileScanner({
    required this.controller,
    this.fit = BoxFit.cover,
  });

  @override
  State<MobileScanner> createState() => _MobileScannerState();
}

class _MobileScannerState extends State<MobileScanner>
    with WidgetsBindingObserver {
  /// The subscription that listens to barcode detection.
  StreamSubscription<BarcodeCapture>? _barcodesSubscription;

  /// Whether the controller should resume
  /// when the application comes back to the foreground.
  bool _resumeFromBackground = false;

  /// Restart a previously paused scanner.
  void _restartScanner() {
    widget.controller.start().then((arguments) {
      widget.onScannerRestarted?.call(arguments);
    }).catchError((error) {
      // The scanner somehow failed to restart.
      // There is no way to recover from this, so do nothing.
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _barcodesSubscription = widget.controller.barcodes.listen(
      widget.onBarcodeDetected,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before the controller was initialized.
    if (widget.controller.isStarting) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _resumeFromBackground = false;
        _restartScanner();
        break;
      case AppLifecycleState.paused:
        _resumeFromBackground = true;
        break;
      case AppLifecycleState.inactive:
        if (!_resumeFromBackground) {
          widget.controller.stop();
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.startArguments,
      builder: (context, value, child) {
        value = value as MobileScannerArguments?;
        if (value == null) {
          return const ColoredBox(color: Colors.black);
        } else {
          controller.barcodes.listen((barcode) {
            widget.onDetect(barcode);
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
    WidgetsBinding.instance.removeObserver(this);
    _barcodesSubscription?.cancel();
    super.dispose();
  }
}
