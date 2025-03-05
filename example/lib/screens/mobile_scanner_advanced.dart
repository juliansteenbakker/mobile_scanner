import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/widgets/buttons/analyze_image_button.dart';
import 'package:mobile_scanner_example/widgets/buttons/pause_button.dart';
import 'package:mobile_scanner_example/widgets/buttons/start_stop_button.dart';
import 'package:mobile_scanner_example/widgets/buttons/switch_camera_button.dart';
import 'package:mobile_scanner_example/widgets/buttons/toggle_flashlight_button.dart';
import 'package:mobile_scanner_example/widgets/dialogs/barcode_format_dialog.dart';
import 'package:mobile_scanner_example/widgets/dialogs/box_fit_dialog.dart';
import 'package:mobile_scanner_example/widgets/dialogs/detection_speed_dialog.dart';
import 'package:mobile_scanner_example/widgets/dialogs/detection_timeout_dialog.dart';
import 'package:mobile_scanner_example/widgets/dialogs/resolution_dialog.dart';
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
}

/// Implementation of Mobile Scanner example with advanced configuration
class MobileScannerAdvanced extends StatefulWidget {
  /// Constructor for advanced Mobile Scanner example
  const MobileScannerAdvanced({super.key});

  @override
  State<MobileScannerAdvanced> createState() => _MobileScannerAdvancedState();
}

class _MobileScannerAdvancedState extends State<MobileScannerAdvanced> {
  // Cannot be changed while the scanner is running.
  static const useScanWindow = true;

  late MobileScannerController controller = initController();

  bool autoZoom = false;
  bool invertImage = false;
  bool returnImage = false;

  Size desiredCameraResolution = const Size(1920, 1080);
  DetectionSpeed detectionSpeed = DetectionSpeed.unrestricted;
  int detectionTimeoutMs = 1000;

  bool useBarcodeOverlay = true;
  BoxFit boxFit = BoxFit.contain;
  bool enableLifecycle = false;

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
      );

  @override
  void initState() {
    super.initState();
    unawaited(controller.start());
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }

  Future<void> _showResolutionDialog() async {
    final result = await showDialog<Size>(
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
    final result = await showDialog<DetectionSpeed>(
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
    final result = await showDialog<int>(
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
    final result = await showDialog<BoxFit>(
      context: context,
      builder: (context) => BoxFitDialog(selectedBoxFit: boxFit),
    );

    if (result != null) {
      setState(() {
        boxFit = result;
      });
    }
  }

  Future<void> _showBarcodeFormatDialog() async {
    final result = await showDialog<List<BarcodeFormat>>(
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
              }

              await controller.dispose();
              controller = initController();
              await controller.start();

              if (!mounted) return;

              setState(() {});
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
            ],
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            // useAppLifecycleState: false, // Only set to false if you want
            // to handle lifecycle changes yourself
            scanWindow: useScanWindow ? scanWindow : null,
            controller: controller,
            errorBuilder: (context, error) {
              return ScannerErrorWidget(error: error);
            },
            fit: boxFit,
          ),
          if (useBarcodeOverlay)
            BarcodeOverlay(controller: controller, boxFit: boxFit),
          // The scanWindow is not supported on the web.
          if (!kIsWeb && useScanWindow)
            ScanWindowOverlay(
              scanWindow: scanWindow,
              controller: controller,
            ),
          if (returnImage)
            Align(
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
                    stream: controller.barcodes,
                    builder: (context, snapshot) {
                      final barcode = snapshot.data;

                      if (barcode == null) {
                        return const Center(
                          child: Text(
                            'Your scanned barcode will appear here',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final barcodeImage = barcode.image;

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
                            child: Text('Could not decode image bytes. $error'),
                          );
                        },
                      );
                    },
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
                      barcodes: controller.barcodes,
                    ),
                  ),
                  if (!kIsWeb) ZoomScaleSlider(controller: controller),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ToggleFlashlightButton(controller: controller),
                      StartStopButton(controller: controller),
                      PauseButton(controller: controller),
                      SwitchCameraButton(controller: controller),
                      AnalyzeImageButton(controller: controller),
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
