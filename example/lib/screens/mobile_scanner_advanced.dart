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
import 'package:mobile_scanner_example/widgets/scanned_barcode_label.dart';
import 'package:mobile_scanner_example/widgets/scanner_error_widget.dart';

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

  final widthController = TextEditingController();
  final heightController = TextEditingController();

  late MobileScannerController controller = initController();

  bool autoZoom = false;
  bool invertImage = false;
  bool returnImage = false;

  Size desiredCameraResolution = const Size(1920, 1080);
  DetectionSpeed detectionSpeed = DetectionSpeed.unrestricted;
  int detectionTimeout = 1000; // Default to 1000ms

  bool useBarcodeOverlay = true;
  BoxFit boxFit = BoxFit.contain;
  bool enableLifecycle = false;

  List<BarcodeFormat> selectedFormats = [];
  double _zoomFactor = 0;

  MobileScannerController initController() => MobileScannerController(
        autoStart: false,
        cameraResolution: desiredCameraResolution,
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

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
    widthController.dispose();
    heightController.dispose();
  }

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

  Future<void> _showResolutionDialog() async => showDialog<void>(
        context: context,
        builder: (context) {
          widthController.text =
              desiredCameraResolution.width.toInt().toString();
          heightController.text =
              desiredCameraResolution.height.toInt().toString();

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
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final widthText = widthController.text.trim();
                  final heightText = heightController.text.trim();

                  // Check for empty input
                  if (widthText.isEmpty || heightText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Width and Height cannot be empty'),
                      ),
                    );
                    return;
                  }

                  final width = int.tryParse(widthText);
                  final height = int.tryParse(heightText);

                  // Check if values are valid numbers
                  if (width == null || height == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid numbers'),
                      ),
                    );
                    return;
                  }

                  // Ensure values are within a reasonable range
                  if (width <= 144 || height <= 144) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Width and Height must be greater than 144'),
                      ),
                    );
                    return;
                  }

                  if (width > 4000 || height > 4000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Width and Height must be 4000 or less'),
                      ),
                    );
                    return;
                  }

                  // setState(() {
                  desiredCameraResolution =
                      Size(width.toDouble(), height.toDouble());
                  // });

                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

  Future<void> _showDetectionSpeedDialog() async => showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select Detection Speed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final speed in DetectionSpeed.values)
                  RadioListTile<DetectionSpeed>(
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
                  ),
              ],
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

              setState(() {});
            },
            itemBuilder: (context) => [
              if (Platform.isAndroid)
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
              if (Platform.isAndroid)
                CheckedPopupMenuItem(
                  value: _PopupMenuItems.autoZoom,
                  checked: autoZoom,
                  child: Text(_PopupMenuItems.autoZoom.name),
                ),
              if (Platform.isAndroid)
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
}
