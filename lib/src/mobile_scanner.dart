import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/mobile_scanner_arguments.dart';

/// The function signature for the error builder.
typedef MobileScannerErrorBuilder = Widget Function(
  BuildContext,
  MobileScannerException,
  Widget?,
);

/// The [MobileScanner] widget displays a live camera preview.
class MobileScanner extends StatefulWidget {
  /// The controller that manages the barcode scanner.
  ///
  /// If this is null, the scanner will manage its own controller.
  final MobileScannerController? controller;

  /// The function that builds an error widget when the scanner
  /// could not be started.
  ///
  /// If this is null, defaults to a black [ColoredBox]
  /// with a centered white [Icons.error] icon.
  final MobileScannerErrorBuilder? errorBuilder;

  /// The [BoxFit] for the camera preview.
  ///
  /// Defaults to [BoxFit.cover].
  final BoxFit fit;

  /// The function that signals when new codes were detected by the [controller].
  final void Function(BarcodeCapture barcodes) onDetect;

  /// The function that signals when the barcode scanner is started.
  @Deprecated('Use onScannerStarted() instead.')
  final void Function(MobileScannerArguments? arguments)? onStart;

  /// The function that signals when the barcode scanner is started.
  final void Function(MobileScannerArguments? arguments)? onScannerStarted;

  /// The function that builds a placeholder widget when the scanner
  /// is not yet displaying its camera preview.
  ///
  /// If this is null, a black [ColoredBox] is used as placeholder.
  final Widget Function(BuildContext, Widget?)? placeholderBuilder;

  /// if set barcodes will only be scanned if they fall within this [Rect]
  /// useful for having a cut-out overlay for example. these [Rect]
  /// coordinates are relative to the widget size, so by how much your
  /// rectangle overlays the actual image can depend on things like the
  /// [BoxFit]
  final Rect? scanWindow;

  /// Only set this to true if you are starting another instance of mobile_scanner
  /// right after disposing the first one, like in a PageView.
  ///
  /// Default: false
  final bool startDelay;

  /// Create a new [MobileScanner] using the provided [controller]
  /// and [onBarcodeDetected] callback.
  const MobileScanner({
    this.controller,
    this.errorBuilder,
    this.fit = BoxFit.cover,
    required this.onDetect,
    @Deprecated('Use onScannerStarted() instead.') this.onStart,
    this.onScannerStarted,
    this.placeholderBuilder,
    this.scanWindow,
    this.startDelay = false,
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
  late MobileScannerController _controller;

  /// Whether the controller should resume
  /// when the application comes back to the foreground.
  bool _resumeFromBackground = false;

  MobileScannerException? _startException;

  Widget _buildPlaceholderOrError(BuildContext context, Widget? child) {
    final error = _startException;

    if (error != null) {
      return widget.errorBuilder?.call(context, error, child) ??
          const ColoredBox(
            color: Colors.black,
            child: Center(child: Icon(Icons.error, color: Colors.white)),
          );
    }

    return widget.placeholderBuilder?.call(context, child) ??
        const ColoredBox(color: Colors.black);
  }

  /// Start the given [scanner].
  Future<void> _startScanner() async {
    if (widget.startDelay) {
      await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    }

    _barcodesSubscription ??= _controller.barcodes.listen(
      widget.onDetect,
    );

    if (!_controller.autoStart) {
      debugPrint(
        'mobile_scanner: not starting automatically because autoStart is set to false in the controller.',
      );
      return;
    }

    _controller.start().then((arguments) {
      // ignore: deprecated_member_use_from_same_package
      widget.onStart?.call(arguments);
      widget.onScannerStarted?.call(arguments);
    }).catchError((error) {
      debugPrint('mobile_scanner: $error');
      if (mounted) {
        setState(() {
          _startException = error as MobileScannerException;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controller ?? MobileScannerController();
    _startScanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before the controller was initialized.
    if (_controller.isStarting) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _resumeFromBackground = false;
        _startScanner();
        break;
      case AppLifecycleState.paused:
        _resumeFromBackground = true;
        break;
      case AppLifecycleState.inactive:
        if (!_resumeFromBackground) {
          _controller.stop();
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  /// the [scanWindow] rect will be relative and scaled to the [widgetSize] not the texture. so it is possible,
  /// depending on the [fit], for the [scanWindow] to partially or not at all overlap the [textureSize]
  ///
  /// since when using a [BoxFit] the content will always be centered on its parent. we can convert the rect
  /// to be relative to the texture.
  ///
  /// since the textures size and the actuall image (on the texture size) might not be the same, we also need to
  /// calculate the scanWindow in terms of percentages of the texture, not pixels.
  Rect calculateScanWindowRelativeToTextureInPercentage(
    BoxFit fit,
    Rect scanWindow,
    Size textureSize,
    Size widgetSize,
  ) {
    /// map the texture size to get its new size after fitted to screen
    final fittedTextureSize = applyBoxFit(fit, textureSize, widgetSize);

    /// create a new rectangle that represents the texture on the screen
    final minX = widgetSize.width / 2 - fittedTextureSize.destination.width / 2;
    final minY =
        widgetSize.height / 2 - fittedTextureSize.destination.height / 2;
    final textureWindow = Offset(minX, minY) & fittedTextureSize.destination;

    /// create a new scan window and with only the area of the rect intersecting the texture window
    final scanWindowInTexture = scanWindow.intersect(textureWindow);

    /// update the scanWindow left and top to be relative to the texture not the widget
    final newLeft = scanWindowInTexture.left - textureWindow.left;
    final newTop = scanWindowInTexture.top - textureWindow.top;
    final newWidth = scanWindowInTexture.width;
    final newHeight = scanWindowInTexture.height;

    /// new scanWindow that is adapted to the boxfit and relative to the texture
    final windowInTexture = Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);

    /// get the scanWindow as a percentage of the texture
    final percentageLeft =
        windowInTexture.left / fittedTextureSize.destination.width;
    final percentageTop =
        windowInTexture.top / fittedTextureSize.destination.height;
    final percentageRight =
        windowInTexture.right / fittedTextureSize.destination.width;
    final percentagebottom =
        windowInTexture.bottom / fittedTextureSize.destination.height;

    /// this rectangle can be send to native code and used to cut out a rectangle of the scan image
    return Rect.fromLTRB(
      percentageLeft,
      percentageTop,
      percentageRight,
      percentagebottom,
    );
  }

  Rect? scanWindow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<MobileScannerArguments?>(
          valueListenable: _controller.startArguments,
          builder: (context, value, child) {
            if (value == null) {
              return _buildPlaceholderOrError(context, child);
            }

            if (widget.scanWindow != null && scanWindow == null) {
              scanWindow = calculateScanWindowRelativeToTextureInPercentage(
                widget.fit,
                widget.scanWindow!,
                value.size,
                Size(constraints.maxWidth, constraints.maxHeight),
              );

              _controller.updateScanWindow(scanWindow);
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
      },
    );
  }

  @override
  void dispose() {
    _controller.updateScanWindow(null);
    WidgetsBinding.instance.removeObserver(this);
    _barcodesSubscription?.cancel();
    _barcodesSubscription = null;
    _controller.dispose();
    super.dispose();
  }
}
