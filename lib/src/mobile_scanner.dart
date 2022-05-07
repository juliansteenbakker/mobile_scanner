import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/custom_border.dart';

enum Ratio { ratio_4_3, ratio_16_9 }

/// A widget showing a live camera preview.
class MobileScanner extends StatefulWidget {
  /// The controller of the camera.
  final MobileScannerController? controller;

  /// Function that gets called when a Barcode is detected.
  ///
  /// [barcode] The barcode object with all information about the scanned code.
  /// [args] Information about the state of the MobileScanner widget
  final Function(Barcode barcode, MobileScannerArguments? args)? onDetect;

  /// TODO: Function that gets called when the Widget is initialized. Can be usefull
  /// to check wether the device has a torch(flash) or not.
  ///
  /// [args] Information about the state of the MobileScanner widget
  // final Function(MobileScannerArguments args)? onInitialize;

  /// Handles how the widget should fit the screen.
  final BoxFit fit;

  /// Set to false if you don't want duplicate scans.
  final bool allowDuplicates;

  ///Enable or disable the scan region.
  final bool enableScanRegion;

  ///Set the opacity of the overlay (from 0.0 to 1.0).
  ///
  ///Out of range wil have unexpected effects.
  final double overlayOpacity;

  ///Height of the scan region box
  ///
  ///Defaults to the [width] of the texture specified * 0.6
  final double? scanRegionHeight;

  ///Width of the scan region box
  ///
  ///Defaults to the [width] of the texture specified * 0.6
  final double? scanRegionWidth;

  ///Height offset of the scan region box's border
  final double borderHeightOffset;

  ///Width  offset of the scan region box's border
  final double borderWidthOffset;

  ///The stroke width for the scan region border
  final double borderStrokeWidth;

  ///The stroke color for the scan region border
  final Color borderStrokeColor;

  ///Length of scan region border's corner sides
  final double borderCornerSide;

  /// Create a [MobileScanner] with a [controller], the [controller] must has been initialized.
  const MobileScanner({
    Key? key,
    this.onDetect,
    this.controller,
    this.fit = BoxFit.cover,
    this.allowDuplicates = false,
    this.enableScanRegion = true,
    this.overlayOpacity = 0.75,
    this.scanRegionHeight,
    this.scanRegionWidth,
    this.borderHeightOffset = 100,
    this.borderWidthOffset = 100,
    this.borderStrokeWidth = 10,
    this.borderStrokeColor = Colors.redAccent,
    this.borderCornerSide = 50,
  }) : super(key: key);

  @override
  State<MobileScanner> createState() => _MobileScannerState();
}

class _MobileScannerState extends State<MobileScanner>
    with WidgetsBindingObserver {
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    controller = widget.controller ?? MobileScannerController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!controller.isStarting) controller.start();
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
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        return ValueListenableBuilder(
          valueListenable: controller.args,
          builder: (context, value, child) {
            value = value as MobileScannerArguments?;
            if (value == null) {
              return Container(color: Colors.black);
            } else {
              controller.barcodes.listen((barcode) {
                if (!widget.allowDuplicates) {
                  if (lastScanned != barcode.rawValue) {
                    lastScanned = barcode.rawValue;
                    widget.onDetect!(barcode, value! as MobileScannerArguments);
                  }
                } else {
                  widget.onDetect!(barcode, value! as MobileScannerArguments);
                }
              });

              final double scanRegionWidth =
                  widget.scanRegionWidth ?? (value.size.width * 0.6);
              final double scanRegionHeight =
                  widget.scanRegionHeight ?? (value.size.width * 0.6);

              final double scanRegionBorderBoxWidth =
                  scanRegionWidth + widget.borderWidthOffset;
              final double scanRegionBorderBoxHeight =
                  scanRegionHeight + widget.borderHeightOffset;

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
                          : !widget.enableScanRegion
                              ? Texture(textureId: value.textureId!)
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Texture(textureId: value.textureId!),
                                    ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        Colors.black
                                            .withOpacity(widget.overlayOpacity),
                                        BlendMode.srcOut,
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.black,
                                              backgroundBlendMode:
                                                  BlendMode.dstOut,
                                            ),
                                          ),
                                          Center(
                                            child: Container(
                                              height: scanRegionHeight,
                                              width: scanRegionWidth,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Center(
                                      child: CustomPaint(
                                        size: Size(
                                          scanRegionBorderBoxWidth,
                                          scanRegionBorderBoxHeight,
                                        ),
                                        foregroundPainter: BorderPainter(
                                          strokeWidth: widget.borderStrokeWidth,
                                          boxWidth: scanRegionBorderBoxWidth,
                                          boxHeight: scanRegionBorderBoxHeight,
                                          strokeColor: widget.borderStrokeColor,
                                          cornerSide: widget.borderCornerSide,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                    ),
                  ),
                ),
              );
            }
          },
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
        controller = MobileScannerController();
      } else if (oldWidget.controller != widget.controller) {
        controller = widget.controller!;
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }
}
