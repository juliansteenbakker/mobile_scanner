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

  /// The overlay which will be painted above the scanner when has started successful.
  /// Will no be pointed when an error occurs or the scanner hasn't be started yet.
  final Widget? overlay;

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
    this.overlay,
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
        if (_resumeFromBackground) {
          _startScanner();
        }
        break;
      case AppLifecycleState.inactive:
        _resumeFromBackground = true;
        _controller.stop();
        break;
      default:
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
    double fittedTextureWidth;
    double fittedTextureHeight;

    switch (fit) {
      case BoxFit.contain:
        final widthRatio = widgetSize.width / textureSize.width;
        final heightRatio = widgetSize.height / textureSize.height;
        final scale = widthRatio < heightRatio ? widthRatio : heightRatio;
        fittedTextureWidth = textureSize.width * scale;
        fittedTextureHeight = textureSize.height * scale;
        break;

      case BoxFit.cover:
        final widthRatio = widgetSize.width / textureSize.width;
        final heightRatio = widgetSize.height / textureSize.height;
        final scale = widthRatio > heightRatio ? widthRatio : heightRatio;
        fittedTextureWidth = textureSize.width * scale;
        fittedTextureHeight = textureSize.height * scale;
        break;

      case BoxFit.fill:
        fittedTextureWidth = widgetSize.width;
        fittedTextureHeight = widgetSize.height;
        break;

      case BoxFit.fitHeight:
        final ratio = widgetSize.height / textureSize.height;
        fittedTextureWidth = textureSize.width * ratio;
        fittedTextureHeight = widgetSize.height;
        break;

      case BoxFit.fitWidth:
        final ratio = widgetSize.width / textureSize.width;
        fittedTextureWidth = widgetSize.width;
        fittedTextureHeight = textureSize.height * ratio;
        break;

      case BoxFit.none:
      case BoxFit.scaleDown:
        fittedTextureWidth = textureSize.width;
        fittedTextureHeight = textureSize.height;
        break;
    }

    final offsetX = (widgetSize.width - fittedTextureWidth) / 2;
    final offsetY = (widgetSize.height - fittedTextureHeight) / 2;

    final left = (scanWindow.left - offsetX) / fittedTextureWidth;
    final top = (scanWindow.top - offsetY) / fittedTextureHeight;
    final right = (scanWindow.right - offsetX) / fittedTextureWidth;
    final bottom = (scanWindow.bottom - offsetY) / fittedTextureHeight;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect? scanWindow;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

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
            size,
          );

          _controller.updateScanWindow(scanWindow);
        }
        if (widget.overlay != null) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _scanner(value.size, value.webId, value.textureId),
              widget.overlay!
            ],
          );
        } else {
          return _scanner(value.size, value.webId, value.textureId);
        }
      },
    );
  }

  Widget _scanner(Size size, String? webId, int? textureId) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (_, constraints) {
          return SizedBox.fromSize(
            size: constraints.biggest,
            child: FittedBox(
              fit: widget.fit,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: kIsWeb
                    ? HtmlElementView(viewType: webId!)
                    : Texture(textureId: textureId!),
              ),
            ),
          );
        },
      ),
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
