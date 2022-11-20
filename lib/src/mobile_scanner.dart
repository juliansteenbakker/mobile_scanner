import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/mobile_scanner_arguments.dart';

/// The [MobileScanner] widget displays a live camera preview.
class MobileScanner extends StatefulWidget {
  /// The controller that manages the barcode scanner.
  final MobileScannerController controller;

  /// The [BoxFit] for the camera preview.
  ///
  /// Defaults to [BoxFit.cover].
  final BoxFit fit;

  /// The function that signals when new barcodes were detected by the [controller].
  final void Function(BarcodeCapture barcodes) onBarcodeDetected;

  /// The function that signals when the barcode scanner is restarted,
  /// due to coming back to the foreground.
  final void Function(MobileScannerArguments? arguments)? onScannerRestarted;

  /// The function that builds a placeholder widget when the scanner
  /// is not yet displaying its camera preview.
  ///
  /// If this is null, a black [ColoredBox] is used as placeholder.
  final Widget Function(BuildContext, Widget?)? placeholderBuilder;

  /// Create a new [MobileScanner] using the provided [controller]
  /// and [onBarcodeDetected] callback.
  const MobileScanner({
    required this.controller,
    this.fit = BoxFit.cover,
    required this.onBarcodeDetected,
    this.onScannerRestarted,
    this.placeholderBuilder,
    super.key,
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
    return ValueListenableBuilder<MobileScannerArguments?>(
      valueListenable: widget.controller.startArguments,
      builder: (context, value, child) {
        if (value == null) {
          return widget.placeholderBuilder?.call(context, child) ??
              const ColoredBox(color: Colors.black);
        }

        return ClipRect(
          child: LayoutBuilder(
            builder: (_, constraints) {
              return SizedBox.fromSize(
                size: constraints.biggest,
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
              );
            },
          ),
        );
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
