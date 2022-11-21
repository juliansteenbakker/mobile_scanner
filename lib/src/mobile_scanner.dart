import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/mobile_scanner_arguments.dart';

/// The [MobileScanner] widget displays a live camera preview.
class MobileScanner extends StatefulWidget {
  /// The controller that manages the barcode scanner.
  ///
  /// If this is null, the scanner will manage its own controller.
  final MobileScannerController? controller;

  /// The [BoxFit] for the camera preview.
  ///
  /// Defaults to [BoxFit.cover].
  final BoxFit fit;

  /// The function that signals when new barcodes were detected by the [controller].
  final void Function(BarcodeCapture barcodes) onBarcodeDetected;

  /// The function that signals when the barcode scanner is started.
  final void Function(MobileScannerArguments? arguments)? onScannerStarted;

  /// The function that builds a placeholder widget when the scanner
  /// is not yet displaying its camera preview.
  ///
  /// If this is null, a black [ColoredBox] is used as placeholder.
  final Widget Function(BuildContext, Widget?)? placeholderBuilder;

  /// Create a new [MobileScanner] using the provided [controller]
  /// and [onBarcodeDetected] callback.
  const MobileScanner({
    this.controller,
    this.fit = BoxFit.cover,
    required this.onBarcodeDetected,
    this.onScannerStarted,
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

  /// The internally managed controller.
  MobileScannerController? _controller;

  /// Get the effective controller.
  MobileScannerController get _effectiveController {
    if (widget.controller != null) {
      return widget.controller!;
    }

    return _controller!;
  }

  /// Whether the controller should resume
  /// when the application comes back to the foreground.
  bool _resumeFromBackground = false;

  /// Start the given [scanner].
  void _startScanner(MobileScannerController scanner) {
    scanner.start().then((arguments) {
      widget.onScannerStarted?.call(arguments);
    }).catchError((error) {
      // The scanner somehow failed to start.
      // There is no way to recover from this, so do nothing.
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.controller == null) {
      _controller = MobileScannerController();
    }

    _barcodesSubscription = _effectiveController.barcodes.listen(
      widget.onBarcodeDetected,
    );

    final internalController = _controller;

    if (internalController != null && !internalController.isStarting) {
      _startScanner(internalController);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before the controller was initialized.
    if (_effectiveController.isStarting) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _resumeFromBackground = false;
        _startScanner(_effectiveController);
        break;
      case AppLifecycleState.paused:
        _resumeFromBackground = true;
        break;
      case AppLifecycleState.inactive:
        if (!_resumeFromBackground) {
          _effectiveController.stop();
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void didUpdateWidget(covariant MobileScanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller == null) {
      if (widget.controller != null) {
        _controller?.dispose();
        _controller = widget.controller;
      }
    } else {
      if (widget.controller == null) {
        _controller = MobileScannerController();
      } else if (oldWidget.controller != widget.controller) {
        _controller = widget.controller;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerArguments?>(
      valueListenable: _effectiveController.startArguments,
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
    _controller?.dispose();
    super.dispose();
  }
}
