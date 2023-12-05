import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:mobile_scanner_example/scanner_error_widget.dart';

class BarcodeScannerWithZoom extends StatefulWidget {
  const BarcodeScannerWithZoom({super.key});

  @override
  State<BarcodeScannerWithZoom> createState() => _BarcodeScannerWithZoomState();
}

class _BarcodeScannerWithZoomState extends State<BarcodeScannerWithZoom>
    with SingleTickerProviderStateMixin {
  BarcodeCapture? barcode;

  MobileScannerController controller = MobileScannerController(
    torchEnabled: true,
  );

  bool isStarted = true;
  double _zoomFactor = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('With zoom slider')),
      backgroundColor: Colors.black,
      body: Builder(
        builder: (context) {
          return Stack(
            children: [
              MobileScanner(
                controller: controller,
                fit: BoxFit.contain,
                errorBuilder: (context, error, child) {
                  return ScannerErrorWidget(error: error);
                },
                onDetect: (barcode) {
                  setState(() {
                    this.barcode = barcode;
                  });
                },
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  alignment: Alignment.bottomCenter,
                  height: 100,
                  color: Colors.black.withOpacity(0.4),
                  child: Column(
                    children: [
                      Slider(
                        value: _zoomFactor,
                        onChanged: (value) {
                          setState(() {
                            _zoomFactor = value;
                            controller.setZoomScale(value);
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            color: Colors.white,
                            icon: ValueListenableBuilder<TorchState>(
                              valueListenable: controller.torchState,
                              builder: (context, state, child) {
                                switch (state) {
                                  case TorchState.off:
                                    return const Icon(
                                      Icons.flash_off,
                                      color: Colors.grey,
                                    );
                                  case TorchState.on:
                                    return const Icon(
                                      Icons.flash_on,
                                      color: Colors.yellow,
                                    );
                                }
                              },
                            ),
                            iconSize: 32.0,
                            onPressed: () => controller.toggleTorch(),
                          ),
                          IconButton(
                            color: Colors.white,
                            icon: isStarted
                                ? const Icon(Icons.stop)
                                : const Icon(Icons.play_arrow),
                            iconSize: 32.0,
                            onPressed: () => setState(() {
                              isStarted
                                  ? controller.stop()
                                  : controller.start();
                              isStarted = !isStarted;
                            }),
                          ),
                          Center(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 200,
                              height: 50,
                              child: FittedBox(
                                child: Text(
                                  barcode?.barcodes.first.rawValue ??
                                      'Scan something!',
                                  overflow: TextOverflow.fade,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium!
                                      .copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            color: Colors.white,
                            icon: ValueListenableBuilder<CameraFacing>(
                              valueListenable: controller.cameraFacingState,
                              builder: (context, state, child) {
                                switch (state) {
                                  case CameraFacing.front:
                                    return const Icon(Icons.camera_front);
                                  case CameraFacing.back:
                                    return const Icon(Icons.camera_rear);
                                }
                              },
                            ),
                            iconSize: 32.0,
                            onPressed: () => controller.switchCamera(),
                          ),
                          IconButton(
                            color: Colors.white,
                            icon: const Icon(Icons.image),
                            iconSize: 32.0,
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              // Pick an image
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (image != null) {
                                if (await controller.analyzeImage(image.path)) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Barcode found!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No barcode found!'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
