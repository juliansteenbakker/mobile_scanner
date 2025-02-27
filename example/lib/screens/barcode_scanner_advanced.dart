import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/widgets/buttons/analyze_image_button.dart';
import 'package:mobile_scanner_example/widgets/buttons/pause_button.dart';
import 'package:mobile_scanner_example/widgets/buttons/start_stop_button.dart';
import 'package:mobile_scanner_example/widgets/buttons/switch_camera_button.dart';
import 'package:mobile_scanner_example/widgets/buttons/toggle_flashlight_widget.dart';
import 'package:mobile_scanner_example/widgets/scanned_barcode_label.dart';
import 'package:mobile_scanner_example/widgets/scanner_error_widget.dart';

enum PopupMenuItems {
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

class BarcodeScannerAdvanced extends StatefulWidget {
  const BarcodeScannerAdvanced({super.key});

  @override
  State<BarcodeScannerAdvanced> createState() => _BarcodeScannerAdvancedState();
}

class _BarcodeScannerAdvancedState extends State<BarcodeScannerAdvanced> {

  // Cannot be changed on runtime while the scanner is running
  static const useScanWindow = true;

  bool autoZoom = false;
  bool invertImage = false;
  bool returnImage = false;

  Size size = const Size(1920, 1080);
  DetectionSpeed detectionSpeed = DetectionSpeed.unrestricted;
  int detectionTimeout = 1000; // Default to 1000ms

  bool useBarcodeOverlay = true;
  BoxFit boxFit = BoxFit.contain;
  bool enableLifecycle = false;

  List<BarcodeFormat> selectedFormats = [];

  late MobileScannerController controller = initController();

  MobileScannerController initController() => MobileScannerController(
        autoStart: false,
        cameraResolution: size,
        detectionSpeed: detectionSpeed,
        detectionTimeoutMs: detectionTimeout,
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

  double _zoomFactor = 0;

  Widget _buildZoomScaleSlider() {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }

        _zoomFactor = state.zoomScale;

        final labelStyle = Theme.of(context)
            .textTheme
            .headlineMedium!
            .copyWith(color: Colors.white);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Text(
                '0%',
                overflow: TextOverflow.fade,
                style: labelStyle,
              ),
              Expanded(
                child: Slider(
                  value: _zoomFactor,
                  onChanged: (value) {
                    setState(() {
                      _zoomFactor = value;
                      controller.setZoomScale(value);
                    });
                  },
                ),
              ),
              Text(
                '100%',
                overflow: TextOverflow.fade,
                style: labelStyle,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showResolutionDialog() async {
    final widthController = TextEditingController();
    final heightController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Camera Resolution'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: widthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Width'),
              ),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Height'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final width = int.tryParse(widthController.text);
                final height = int.tryParse(heightController.text);

                if (width != null && height != null) {
                  setState(() {
                    size = Size(width.toDouble(), height.toDouble());
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDetectionSpeedDialog() async => showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select Detection Speed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: DetectionSpeed.values.map((speed) {
                return RadioListTile<DetectionSpeed>(
                  title: Text(speed.name),
                  value: speed,
                  groupValue: detectionSpeed,
                  onChanged: (DetectionSpeed? value) {
                    if (value != null) {
                      setState(() {
                        detectionSpeed = value;
                      });
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
          );
        },
      );

  Future<void> _showDetectionTimeoutDialog() async => showDialog<void>(
        context: context,
        builder: (context) {
          var tempTimeout =
              detectionTimeout; // Temporary variable to hold the slider value

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Set Detection Timeout (ms)'),
                content: SizedBox(
                  height: 100, // Restrict height
                  child: Column(
                    children: [
                      Slider(
                        value: tempTimeout.toDouble(),
                        max: 5000,
                        divisions: 50,
                        label: '$tempTimeout ms',
                        onChanged: (double value) {
                          setDialogState(() {
                            tempTimeout = value.toInt();
                          });
                        },
                      ),
                      Text('$tempTimeout ms'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        detectionTimeout = tempTimeout; // Save final selection
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );

  Future<void> _showBoxFitDialog() async => showDialog<void>(
        context: context,
        builder: (context) {
          var tempBoxFit = boxFit; // Temporary variable for selection

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Select BoxFit'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: BoxFit.values.map((fit) {
                    return RadioListTile<BoxFit>(
                      title:
                          Text(fit.toString().split('.').last), // Display name
                      value: fit,
                      groupValue: tempBoxFit,
                      onChanged: (BoxFit? value) {
                        if (value != null) {
                          setDialogState(() {
                            tempBoxFit = value;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        boxFit = tempBoxFit; // Save the selected value
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );

  Future<void> _showBarcodeFormatDialog() async => showDialog<void>(
        context: context,
        builder: (context) {
          final tempSelectedFormats = List<BarcodeFormat>.from(
            selectedFormats,
          ); // Copy of selected formats

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Select Barcode Formats'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: BarcodeFormat.values.map((format) {
                      return CheckboxListTile(
                        title: Text(format.name.toUpperCase()),
                        value: tempSelectedFormats.contains(format),
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value ?? false) {
                              tempSelectedFormats.add(format);
                            } else {
                              tempSelectedFormats.remove(format);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      setState(() {
                        selectedFormats = tempSelectedFormats; // Save selection
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );

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
          PopupMenuButton<PopupMenuItems>(
            tooltip: 'Menu',
            onSelected: (item) async {
              switch (item) {
                case PopupMenuItems.cameraResolution:
                  await _showResolutionDialog();
                case PopupMenuItems.detectionSpeed:
                  await _showDetectionSpeedDialog();
                case PopupMenuItems.detectionTimeout:
                  await _showDetectionTimeoutDialog();
                case PopupMenuItems.formats:
                  await _showBarcodeFormatDialog();
                case PopupMenuItems.boxFit:
                  await _showBoxFitDialog();
                case PopupMenuItems.returnImage:
                  returnImage = !returnImage;
                case PopupMenuItems.invertImage:
                  invertImage = !invertImage;
                case PopupMenuItems.autoZoom:
                  autoZoom = !autoZoom;
                case PopupMenuItems.useBarcodeOverlay:
                  useBarcodeOverlay = !useBarcodeOverlay;
              }

              await controller.dispose();
              controller = initController();
              await controller.start();

              setState(() {});
            },
            itemBuilder: (context) => [
              if (Platform.isAndroid) PopupMenuItem(
                value: PopupMenuItems.cameraResolution,
                child: Text(PopupMenuItems.cameraResolution.name),
              ),
              PopupMenuItem(
                value: PopupMenuItems.detectionSpeed,
                child: Text(PopupMenuItems.detectionSpeed.name),
              ),
              PopupMenuItem(
                value: PopupMenuItems.detectionTimeout,
                enabled: detectionSpeed == DetectionSpeed.normal,
                child: Text(PopupMenuItems.detectionTimeout.name),
              ),
              PopupMenuItem(
                value: PopupMenuItems.boxFit,
                child: Text(PopupMenuItems.boxFit.name),
              ),
              PopupMenuItem(
                value: PopupMenuItems.formats,
                child: Text(PopupMenuItems.formats.name),
              ),
              const PopupMenuDivider(),
              if (Platform.isAndroid) CheckedPopupMenuItem(
                value: PopupMenuItems.autoZoom,
                checked: autoZoom,
                child: Text(PopupMenuItems.autoZoom.name),
              ),
              if (Platform.isAndroid) CheckedPopupMenuItem(
                value: PopupMenuItems.invertImage,
                checked: invertImage,
                child: Text(PopupMenuItems.invertImage.name),
              ),
              CheckedPopupMenuItem(
                value: PopupMenuItems.returnImage,
                checked: returnImage,
                child: Text(PopupMenuItems.returnImage.name),
              ),
              CheckedPopupMenuItem(
                value: PopupMenuItems.useBarcodeOverlay,
                checked: useBarcodeOverlay,
                child: Text(PopupMenuItems.useBarcodeOverlay.name),
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
          if (useScanWindow)
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
                  if (!kIsWeb) _buildZoomScaleSlider(),
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

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }
}
