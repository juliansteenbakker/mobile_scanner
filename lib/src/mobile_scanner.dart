import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/mobile_scanner_state.dart';
import 'package:mobile_scanner/src/objects/scanner_error_widget.dart';
import 'package:mobile_scanner/src/scan_window_calculation.dart';

/// This widget displays a live camera preview for the barcode scanner.
class MobileScanner extends StatefulWidget {
  /// Create a new [MobileScanner] using the provided [controller].
  const MobileScanner({
    this.controller,
    this.onDetect,
    this.onDetectError = _onDetectErrorHandler,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.overlayBuilder,
    this.placeholderBuilder,
    this.scanWindow,
    this.scanWindowUpdateThreshold = 0.0,
    this.useAppLifecycleState = true,
    super.key,
  });

  /// The controller for the camera preview.
  final MobileScannerController? controller;

  /// The function that signals when new codes were detected by the [controller].
  ///
  /// To handle both [BarcodeCapture]s and [MobileScannerBarcodeException]s,
  /// use the [MobileScannerController.barcodes] stream directly (recommended),
  /// or provide a function to [onDetectError].
  final void Function(BarcodeCapture barcodes)? onDetect;

  /// The error handler equivalent for the [onDetect] function.
  ///
  /// If [onDetect] is not null, and this is null, errors are silently ignored.
  final void Function(Object error, StackTrace stackTrace) onDetectError;

  /// The error builder for the camera preview.
  ///
  /// If this is null, a black [ColoredBox],
  /// with a centered white [Icons.error] icon is used as error widget.
  final Widget Function(BuildContext, MobileScannerException)? errorBuilder;

  /// The [BoxFit] for the camera preview.
  ///
  /// Defaults to [BoxFit.cover].
  final BoxFit fit;

  /// The builder for the overlay above the camera preview.
  ///
  /// The resulting widget can be combined with the [scanWindow] rectangle
  /// to create a cutout for the camera preview.
  ///
  /// The [BoxConstraints] for this builder
  /// are the same constraints that are used to compute the effective [scanWindow].
  ///
  /// The overlay is only displayed when the camera preview is visible.
  final LayoutWidgetBuilder? overlayBuilder;

  /// The placeholder builder for the camera preview.
  ///
  /// If this is null, a black [ColoredBox] is used as placeholder.
  ///
  /// The placeholder is displayed when the camera preview is being initialized.
  final WidgetBuilder? placeholderBuilder;

  /// The scan window rectangle for the barcode scanner.
  /// A scan window is not supported on the web because the scanner does not
  /// expose size information for the barcodes.
  ///
  /// If this is not null, the barcode scanner will only scan barcodes
  /// which intersect this rectangle.
  ///
  /// This rectangle is relative to the layout size
  /// of the *camera preview widget* in the widget tree,
  /// rather than the actual size of the camera preview output.
  /// This is because the size of the camera preview widget
  /// might not be the same as the size of the camera output.
  ///
  /// For example, the applied [fit] has an effect on the size of the camera preview widget,
  /// while the camera preview size remains the same.
  ///
  /// The following example shows a scan window that is centered,
  /// fills half the height and one third of the width of the layout:
  ///
  /// ```dart
  /// LayoutBuider(
  ///   builder: (BuildContext context, BoxConstraints constraints) {
  ///     final Size layoutSize = constraints.biggest;
  ///
  ///     final double scanWindowWidth = layoutSize.width / 3;
  ///     final double scanWindowHeight = layoutSize.height / 2;
  ///
  ///     final Rect scanWindow = Rect.fromCenter(
  ///       center: layoutSize.center(Offset.zero),
  ///       width: scanWindowWidth,
  ///       height: scanWindowHeight,
  ///     );
  ///   }
  /// );
  /// ```
  final Rect? scanWindow;

  /// The threshold for updates to the [scanWindow].
  /// A [scanWindow] is not supported on the web because the scanner does not
  /// expose size information for the barcodes.
  ///
  /// If the [scanWindow] would be updated,
  /// due to new layout constraints for the scanner,
  /// and the width or height of the new scan window have not changed by this threshold,
  /// then the scan window is not updated.
  ///
  /// It is recommended to set this threshold
  /// if scan window updates cause performance issues.
  ///
  /// Defaults to no threshold for scan window updates.
  final double scanWindowUpdateThreshold;

  /// Whether the `MobileScanner` widget should automatically pause and resume
  /// when the application lifecycle state changes.
  ///
  /// Only applicable if no controller is passed. Otherwise, lifecycleState
  /// should be handled by the user via the controller.
  ///
  /// Defaults to true.
  final bool useAppLifecycleState;

  @override
  State<MobileScanner> createState() => _MobileScannerState();

  /// This empty function is used as the default error handler for [onDetect].
  static void _onDetectErrorHandler(Object error, StackTrace stackTrace) {
    // Do nothing.
  }
}

class _MobileScannerState extends State<MobileScanner>
    with WidgetsBindingObserver {
  late final MobileScannerController controller;

  /// The current scan window.
  Rect? scanWindow;

  /// Calculate the scan window based on the given [constraints].
  ///
  /// If the [scanWindow] is already set, this method does nothing.
  void _maybeUpdateScanWindow(
    MobileScannerState scannerState,
    BoxConstraints constraints,
  ) {
    if (widget.scanWindow == null && scanWindow == null) {
      return;
    } else if (widget.scanWindow == null) {
      scanWindow = null;

      unawaited(controller.updateScanWindow(null));
      return;
    }

    final Rect newScanWindow = calculateScanWindowRelativeToTextureInPercentage(
      widget.fit,
      widget.scanWindow!,
      textureSize: scannerState.size,
      widgetSize: constraints.biggest,
    );

    // The scan window was never set before.
    // Set the initial scan window.
    if (scanWindow == null) {
      scanWindow = newScanWindow;

      unawaited(controller.updateScanWindow(scanWindow));

      return;
    }

    // The scan window did not not change.
    // The left, right, top and bottom are the same.
    if (scanWindow == newScanWindow) {
      return;
    }

    // The update threshold is not set, allow updating the scan window.
    if (widget.scanWindowUpdateThreshold == 0.0) {
      scanWindow = newScanWindow;

      unawaited(controller.updateScanWindow(scanWindow));

      return;
    }

    final double dx = (newScanWindow.width - scanWindow!.width).abs();
    final double dy = (newScanWindow.height - scanWindow!.height).abs();

    // The new scan window has changed enough, allow updating the scan window.
    if (dx >= widget.scanWindowUpdateThreshold ||
        dy >= widget.scanWindowUpdateThreshold) {
      scanWindow = newScanWindow;

      unawaited(controller.updateScanWindow(scanWindow));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (BuildContext context, MobileScannerState value, _) {
        if (!value.isInitialized) {
          const Widget defaultPlaceholder = ColoredBox(color: Colors.black);

          return widget.placeholderBuilder?.call(context) ?? defaultPlaceholder;
        }

        final MobileScannerException? error = value.error;
        if (error != null) {
          final Widget defaultError = ScannerErrorWidget(error: error);

          return widget.errorBuilder?.call(context, error) ?? defaultError;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            _maybeUpdateScanWindow(value, constraints);

            final Widget? overlay = widget.overlayBuilder?.call(
              context,
              constraints,
            );
            final Size cameraPreviewSize = value.size;

            final Widget scannerWidget = ClipRect(
              child: SizedBox.fromSize(
                size: constraints.biggest,
                child: FittedBox(
                  fit: widget.fit,
                  child: SizedBox(
                    width: cameraPreviewSize.width,
                    height: cameraPreviewSize.height,
                    child: MobileScannerPlatform.instance.buildCameraView(),
                  ),
                ),
              ),
            );

            if (overlay == null) {
              return scannerWidget;
            }

            return Stack(
              alignment: Alignment.center,
              children: <Widget>[scannerWidget, overlay],
            );
          },
        );
      },
    );
  }

  StreamSubscription? _subscription;

  Future<void> initMobileScanner() async {
    // If debug mode is enabled, stop the controller first before starting it.
    // If a hot-restart is initiated, the controller won't be stopped, and because
    // there is no way of knowing if a hot-restart has happened, we must assume
    // every start is a hot-restart. Related issue:
    // https://github.com/flutter/flutter/issues/10437
    if (kDebugMode) {
      if (MobileScannerPlatform.instance
          case final MethodChannelMobileScanner implementation) {
        try {
          await implementation.stop(force: true);
        } catch (e) {
          // Don't do anything if the controller is already stopped.
          debugPrint('$e');
        }
      }
    }

    if (widget.controller == null) {
      WidgetsBinding.instance.addObserver(this);
    }

    if (widget.onDetect != null) {
      _subscription = controller.barcodes.listen(
        widget.onDetect,
        onError: widget.onDetectError,
        cancelOnError: false,
      );
    }

    if (controller.autoStart) {
      await controller.start();
    }
  }

  Future<void> disposeMobileScanner() async {
    if (widget.controller == null) {
      WidgetsBinding.instance.removeObserver(this);
    }

    await _subscription?.cancel();
    _subscription = null;

    if (controller.autoStart) {
      await controller.stop();
    }

    // Dispose default controller if not provided by user
    if (widget.controller == null) {
      await controller.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? MobileScannerController();
    unawaited(initMobileScanner());
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    unawaited(disposeMobileScanner());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.useAppLifecycleState || !controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        unawaited(controller.start());
      case AppLifecycleState.inactive:
        unawaited(controller.stop());
    }
  }
}
