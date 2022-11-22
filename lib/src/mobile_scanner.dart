import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/mobile_scanner_arguments.dart';

/// A widget showing a live camera preview.
class MobileScanner extends StatefulWidget {
  /// The controller of the camera.
  final MobileScannerController? controller;

  /// The [BoxFit] for the camera preview.
  final BoxFit fit;

  /// Calls the provided [onPermissionSet] callback when the permission is set.
  // @Deprecated('Use the [onPermissionSet] paremeter in the [MobileScannerController] instead.')
  // ignore: deprecated_consistency
  final Function(bool permissionGranted)? onPermissionSet;

  /// The function that signals when a new code is detected.
  final void Function(BarcodeCapture barcodes) onDetect;

  /// Function that gets called when the scanner is started.
  ///
  /// [arguments] The start arguments of the scanner. This contains the size of
  /// the scanner which can be used to draw a box over the scanner.
  final void Function(MobileScannerArguments? arguments)? onStart;

  /// The function that builds a placeholder widget when the scanner
  /// is not yet displaying its camera preview.
  ///
  /// If this is null, a black [ColoredBox] is used as placeholder.
  final Widget Function(BuildContext, Widget?)? placeholderBuilder;

  /// Create a [MobileScanner] with a [controller], the [controller] must has been initialized.
  const MobileScanner({
    super.key,
    required this.onDetect,
    this.onStart,
    this.controller,
    this.fit = BoxFit.cover,
    @Deprecated('Use the [onPermissionSet] paremeter in the [MobileScannerController] instead.')
        this.onPermissionSet,
    this.placeholderBuilder,
  });

  @override
  State<MobileScanner> createState() => _MobileScannerState();
}

class _MobileScannerState extends State<MobileScanner>
    with WidgetsBindingObserver {
  late MobileScannerController controller;

  StreamSubscription<BarcodeCapture>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = widget.controller ??
        MobileScannerController(onPermissionSet: widget.onPermissionSet);

    _subscription = controller.barcodes.listen(widget.onDetect);

    if (!controller.isStarting) {
      _startScanner();
    }
  }

  Future<void> _startScanner() async {
    final arguments = await controller.start();
    widget.onStart?.call(arguments);
  }

  bool resumeFromBackground = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before it is initialized.
    if (controller.isStarting) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        resumeFromBackground = false;
        _startScanner();
        break;
      case AppLifecycleState.paused:
        resumeFromBackground = true;
        break;
      case AppLifecycleState.inactive:
        if (!resumeFromBackground) controller.stop();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerArguments?>(
      valueListenable: controller.startArguments,
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
  void didUpdateWidget(covariant MobileScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == null) {
      if (widget.controller != null) {
        controller.dispose();
        controller = widget.controller!;
      }
    } else {
      if (widget.controller == null) {
        controller =
            MobileScannerController(onPermissionSet: widget.onPermissionSet);
      } else if (oldWidget.controller != widget.controller) {
        controller = widget.controller!;
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
