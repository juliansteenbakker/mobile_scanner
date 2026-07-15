import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/widgets/buttons/analyze_image_button.dart';
import 'package:mobile_scanner_example/widgets/buttons/pause_button.dart';
import 'package:mobile_scanner_example/widgets/buttons/start_stop_button.dart';
import 'package:mobile_scanner_example/widgets/buttons/switch_camera_button.dart';
import 'package:mobile_scanner_example/widgets/buttons/switch_lens_button.dart';
import 'package:mobile_scanner_example/widgets/buttons/toggle_flashlight_button.dart';
import 'package:mobile_scanner_example/widgets/dialogs/barcode_format_dialog.dart';
import 'package:mobile_scanner_example/widgets/dialogs/box_fit_dialog.dart';
import 'package:mobile_scanner_example/widgets/dialogs/detection_speed_dialog.dart';
import 'package:mobile_scanner_example/widgets/dialogs/detection_timeout_dialog.dart';
import 'package:mobile_scanner_example/widgets/dialogs/resolution_dialog.dart';
import 'package:mobile_scanner_example/widgets/dialogs/web_barcode_reader_dialog.dart';
import 'package:mobile_scanner_example/widgets/scanned_barcode_label.dart';
import 'package:mobile_scanner_example/widgets/scanner_error_widget.dart';
import 'package:mobile_scanner_example/widgets/zoom_scale_slider_widget.dart';

enum _PopupMenuItems {
  cameraResolution,
  detectionSpeed,
  detectionTimeout,
  returnImage,
  invertImage,
  autoZoom,
  useBarcodeOverlay,
  boxFit,
  formats,
  scanWindow,
  showSupportedLenses,
  webBarcodeReader,
}

/// Implementation of Mobile Scanner example with advanced configuration
class MobileScannerAdvanced extends StatefulWidget {
  /// Constructor for advanced Mobile Scanner example
  const MobileScannerAdvanced({super.key});

  @override
  State<MobileScannerAdvanced> createState() => _MobileScannerAdvancedState();
}

class _MobileScannerAdvancedState extends State<MobileScannerAdvanced> {
  MobileScannerController? controller;

  bool useScanWindow = true;

  /// The currently selected web barcode reader backend (web-only).
  WebBarcodeReader selectedWebReader = WebBarcodeReader.auto;

  bool autoZoom = false;
  bool invertImage = false;
  bool returnImage = false;
  bool tapToFocus = true;

  Size desiredCameraResolution = const Size(1920, 1080);
  DetectionSpeed detectionSpeed = DetectionSpeed.unrestricted;
  int detectionTimeoutMs = 1000;

  bool useBarcodeOverlay = true;
  BoxFit boxFit = BoxFit.contain;
  bool enableLifecycle = false;

  CameraLensType currentLensType = CameraLensType.normal;

  /// Hides the MobileScanner widget while the MobileScannerController is
  /// rebuilding
  bool hideMobileScannerWidget = false;

  List<BarcodeFormat> selectedFormats = [];

  MobileScannerController initController() => MobileScannerController(
    autoStart: false,
    cameraResolution: desiredCameraResolution,
    detectionSpeed: detectionSpeed,
    detectionTimeoutMs: detectionTimeoutMs,
    formats: selectedFormats,
    returnImage: returnImage,
    // torchEnabled: true,
    invertImage: invertImage,
    autoZoom: autoZoom,
    lensType: currentLensType,
  );

  @override
  void initState() {
    super.initState();
    controller = initController();
    if (kIsWeb) {
      MobileScannerPlatform.instance.setWebBarcodeReader(selectedWebReader);
    }
    unawaited(_start());
  }

  @override
  void dispose() {
    super.dispose();
    unawaited(_stop());
  }

  Future<void> _start() async {
    await controller!.start();
    if (mounted) setState(() {});
  }

  Future<void> _stop() async {
    await controller?.dispose();
    controller = null;
  }

  Future<void> _showResolutionDialog() async {
    final Size? result = await showDialog<Size>(
      context: context,
      builder: (context) =>
          ResolutionDialog(initialResolution: desiredCameraResolution),
    );

    if (result != null) {
      setState(() {
        desiredCameraResolution = result;
      });
    }
  }

  Future<void> _showDetectionSpeedDialog() async {
    final DetectionSpeed? result = await showDialog<DetectionSpeed>(
      context: context,
      builder: (context) => DetectionSpeedDialog(selectedSpeed: detectionSpeed),
    );

    if (result != null) {
      setState(() {
        detectionSpeed = result;
      });
    }
  }

  Future<void> _showDetectionTimeoutDialog() async {
    final int? result = await showDialog<int>(
      context: context,
      builder: (context) =>
          DetectionTimeoutDialog(initialTimeoutMs: detectionTimeoutMs),
    );

    if (result != null) {
      setState(() {
        detectionTimeoutMs = result;
      });
    }
  }

  Future<void> _showBoxFitDialog() async {
    final BoxFit? result = await showDialog<BoxFit>(
      context: context,
      builder: (context) => BoxFitDialog(selectedBoxFit: boxFit),
    );

    if (result != null) {
      setState(() {
        boxFit = result;
      });
    }
  }

  Future<void> _showWebBarcodeReaderDialog() async {
    final WebBarcodeReader? result = await showDialog<WebBarcodeReader>(
      context: context,
      builder:
          (context) =>
              WebBarcodeReaderDialog(selectedReader: selectedWebReader),
    );

    if (result != null) {
      setState(() {
        selectedWebReader = result;
      });
    }
  }

  Future<void> _showBarcodeFormatDialog() async {
    final List<BarcodeFormat>? result = await showDialog<List<BarcodeFormat>>(
      context: context,
      builder: (context) =>
          BarcodeFormatDialog(selectedFormats: selectedFormats),
    );

    if (result != null) {
      setState(() {
        selectedFormats = result;
      });
    }
  }

  /// This implementation fully disposes and reinitializes the
  /// MobileScannerController every time a setting is changed via the menu.
  ///
  /// This is NOT optimized for production use.
  /// Replacing the controller like this should not happen when MobileScanner is
  /// active. It causes a short visible flicker and can impact user experience.
  ///
  /// The settings should be defined once, or be configurable outside of a
  /// MobileScanner page, not while the MobileScanner is open.
  ///
  /// This is only used here to demonstrate dynamic configuration changes
  /// without restarting the whole app or navigating away from the scanner view.
  Future<void> _reinitializeController() async {
    // Hide the MobileScanner widget temporarily
    setState(() => hideMobileScannerWidget = true);

    // Let the UI settle
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Dispose of the current controller safely
    await controller?.dispose();
    controller = null;

    // Create a new controller with updated configuration
    controller = initController();

    // Apply the web reader preference before starting.
    if (kIsWeb) {
      MobileScannerPlatform.instance.setWebBarcodeReader(selectedWebReader);
    }

    // Show the scanner again
    setState(() => hideMobileScannerWidget = false);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Start scanning again
    await controller?.start();
    if (mounted) setState(() {});
  }

  Future<void> _onLensTypeChanged(CameraLensType newLensType) async {
    setState(() {
      currentLensType = newLensType;
    });
    await _reinitializeController();
  }

  Future<void> _showSupportedLenses() async {
    if (controller == null) return;

    try {
      final Set<CameraLensType> supportedLenses = await controller!
          .getSupportedLenses();
      if (!mounted) return;

      final String lensNames = supportedLenses
          .map((lens) {
            switch (lens) {
              case CameraLensType.normal:
                return 'Normal';
              case CameraLensType.wide:
                return 'Wide/Ultra-Wide';
              case CameraLensType.zoom:
                return 'Zoom/Telephoto';
              case CameraLensType.any:
                return 'Any (Default)';
            }
          })
          .join('\n');

      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supported Lenses'),
            content: Text(
              'Available camera lenses on this device:\n\n$lensNames',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;

      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Could not retrieve supported lenses:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    late final scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(const Offset(0, -100)),
      width: 300,
      height: 200,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Mobile Scanner'),
        actions: [
          PopupMenuButton<_PopupMenuItems>(
            tooltip: 'Menu',
            onSelected: (item) async {
              switch (item) {
                case _PopupMenuItems.cameraResolution:
                  await _showResolutionDialog();
                case _PopupMenuItems.detectionSpeed:
                  await _showDetectionSpeedDialog();
                case _PopupMenuItems.detectionTimeout:
                  await _showDetectionTimeoutDialog();
                case _PopupMenuItems.formats:
                  await _showBarcodeFormatDialog();
                case _PopupMenuItems.boxFit:
                  await _showBoxFitDialog();
                case _PopupMenuItems.returnImage:
                  returnImage = !returnImage;
                case _PopupMenuItems.invertImage:
                  invertImage = !invertImage;
                case _PopupMenuItems.autoZoom:
                  autoZoom = !autoZoom;
                case _PopupMenuItems.useBarcodeOverlay:
                  useBarcodeOverlay = !useBarcodeOverlay;
                case _PopupMenuItems.scanWindow:
                  useScanWindow = !useScanWindow;
                case _PopupMenuItems.showSupportedLenses:
                  await _showSupportedLenses();
                  return; // Don't reinitialize for this action
                case _PopupMenuItems.webBarcodeReader:
                  await _showWebBarcodeReaderDialog();
              }

              // Rebuild and restart the controller with updated settings
              await _reinitializeController();
            },
            itemBuilder: (context) => [
              if (!kIsWeb && Platform.isAndroid)
                PopupMenuItem(
                  value: _PopupMenuItems.cameraResolution,
                  child: Text(_PopupMenuItems.cameraResolution.name),
                ),
              PopupMenuItem(
                value: _PopupMenuItems.detectionSpeed,
                child: Text(_PopupMenuItems.detectionSpeed.name),
              ),
              PopupMenuItem(
                value: _PopupMenuItems.detectionTimeout,
                enabled: detectionSpeed == DetectionSpeed.normal,
                child: Text(_PopupMenuItems.detectionTimeout.name),
              ),
              PopupMenuItem(
                value: _PopupMenuItems.boxFit,
                child: Text(_PopupMenuItems.boxFit.name),
              ),
              PopupMenuItem(
                value: _PopupMenuItems.formats,
                child: Text(_PopupMenuItems.formats.name),
              ),
              const PopupMenuDivider(),
              if (!kIsWeb && Platform.isAndroid)
                CheckedPopupMenuItem(
                  value: _PopupMenuItems.autoZoom,
                  checked: autoZoom,
                  child: Text(_PopupMenuItems.autoZoom.name),
                ),
              if (!kIsWeb && Platform.isAndroid)
                CheckedPopupMenuItem(
                  value: _PopupMenuItems.invertImage,
                  checked: invertImage,
                  child: Text(_PopupMenuItems.invertImage.name),
                ),
              const PopupMenuItem(
                value: _PopupMenuItems.showSupportedLenses,
                child: Text('Show Supported Lenses'),
              ),
              CheckedPopupMenuItem(
                value: _PopupMenuItems.returnImage,
                checked: returnImage,
                child: Text(_PopupMenuItems.returnImage.name),
              ),
              CheckedPopupMenuItem(
                value: _PopupMenuItems.useBarcodeOverlay,
                checked: useBarcodeOverlay,
                child: Text(_PopupMenuItems.useBarcodeOverlay.name),
              ),
              CheckedPopupMenuItem(
                value: _PopupMenuItems.scanWindow,
                checked: useScanWindow,
                child: Text(_PopupMenuItems.scanWindow.name),
              ),
              if (kIsWeb) ...[
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _PopupMenuItems.webBarcodeReader,
                  child: Text(
                    'Web reader: '
                        '${selectedWebReader.shortLabel}',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: controller == null || hideMobileScannerWidget
          ? const Placeholder()
          : Stack(
              children: [
                MobileScanner(
                  // useAppLifecycleState: false, // Only set to false if you want
                  // to handle lifecycle changes yourself
                  scanWindow: useScanWindow ? scanWindow : null,
                  tapToFocus: true,
                  controller: controller,
                  errorBuilder: (context, error) {
                    return ScannerErrorWidget(error: error);
                  },
                  fit: boxFit,
                ),
                if (useBarcodeOverlay)
                  // Needed for tapToFocus
                  IgnorePointer(
                    child: BarcodeOverlay(
                      controller: controller!,
                      boxFit: boxFit,
                    ),
                  ),
                // The scanWindow is not supported on the web.
                if (useScanWindow)
                  // Needed for tapToFocus
                  IgnorePointer(
                    child: ScanWindowOverlay(
                      scanWindow: scanWindow,
                      controller: controller!,
                    ),
                  ),
                if (returnImage)
                  // Needed for tapToFocus
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Card(
                        clipBehavior: Clip.hardEdge,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: StreamBuilder<BarcodeCapture>(
                            stream: controller!.barcodes,
                            builder: (context, snapshot) {
                              final BarcodeCapture? barcode = snapshot.data;

                              if (barcode == null) {
                                return const Center(
                                  child: Text(
                                    'Your scanned barcode will appear here',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              final Uint8List? barcodeImage = barcode.image;

                              if (barcodeImage == null) {
                                return const Center(
                                  child: Text('No image for this barcode.'),
                                );
                              }

                              return Image.memory(
                                barcodeImage,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      'Could not decode image bytes. $error',
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    height: 200,
                    color: const Color.fromRGBO(0, 0, 0, 0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ScannedBarcodeLabel(
                            barcodes: controller!.barcodes,
                          ),
                        ),
                        if (kIsWeb)
                          _WebReaderBadge(
                            preferredReader: selectedWebReader,
                          ),
                        if (!kIsWeb) ZoomScaleSlider(controller: controller!),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ToggleFlashlightButton(controller: controller!),
                            StartStopButton(controller: controller!),
                            PauseButton(controller: controller!),
                            SwitchCameraButton(controller: controller!),
                            if (!kIsWeb)
                              SwitchLensButton(
                                controller: controller!,
                                currentLensType: currentLensType,
                                onLensTypeChanged: _onLensTypeChanged,
                              ),
                            AnalyzeImageButton(controller: controller!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Small badge that shows the currently active web barcode reader.
///
/// Reads `MobileScannerPlatform.instance.activeWebReader` on every build.
/// The displayed name updates after the scanner is (re)started.
class _WebReaderBadge extends StatelessWidget {
  const _WebReaderBadge({required this.preferredReader});

  final WebBarcodeReader preferredReader;

  @override
  Widget build(BuildContext context) {
    final WebBarcodeReader? active =
        MobileScannerPlatform.instance.activeWebReader;

    final label =
        active != null
            ? 'Reader: ${active.label}'
            : 'Reader: ${preferredReader.label} (not started)';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
