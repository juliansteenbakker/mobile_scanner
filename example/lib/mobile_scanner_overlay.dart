import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/scanner_error_widget.dart';

class BarcodeScannerWithOverlay extends StatefulWidget {
  @override
  _BarcodeScannerWithOverlayState createState() =>
      _BarcodeScannerWithOverlayState();
}

class _BarcodeScannerWithOverlayState extends State<BarcodeScannerWithOverlay> {
  String overlayText = "Please scan QR Code";
  bool camStarted = false;
  BarcodeCapture? currentBarcodeCapture;
  final MobileScannerController controller = MobileScannerController(
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
    autoStart: false,
  );

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }

  void startCamera() {
    setState(() {
      camStarted = !camStarted;
      controller.start();
    });
  }

  void onBarcodeDetect(BarcodeCapture barcodeCapture) {
    setState(() {
      currentBarcodeCapture = barcodeCapture;
      overlayText = barcodeCapture.barcodes.last.displayValue!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 200,
      height: 200,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner with Overlay Example app'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: camStarted
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: MobileScanner(
                            fit: BoxFit.contain,
                            onDetect: onBarcodeDetect,
                            overlay: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Opacity(
                                  opacity: 0.7,
                                  child: Text(
                                    overlayText,
                                    style: const TextStyle(
                                      backgroundColor: Colors.black26,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                            controller: controller,
                            scanWindow: scanWindow,
                            errorBuilder: (context, error, child) {
                              return ScannerErrorWidget(error: error);
                            },
                          ),
                        ),
                        CustomPaint(
                          painter: ScannerOverlay(scanWindow),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () => controller.toggleTorch(),
                                  icon: Icon(
                                    Icons.flashlight_on,
                                    color: controller.torchEnabled
                                        ? Colors.yellow
                                        : Colors.black,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => controller.switchCamera(),
                                  icon: const Icon(
                                    Icons.cameraswitch_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Text("Tap on Camera to activate QR Scanner")),
            ),
          ],
        ),
      ),
      floatingActionButton: camStarted
          ? null
          : FloatingActionButton(
              child: const Icon(
                Icons.camera_alt,
              ),
              onPressed: () {
                startCamera();
              },
            ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  ScannerOverlay(this.scanWindow);

  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()..addRect(scanWindow);

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    // Create a Paint object for the white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0; // Adjust the border width as needed

    // Calculate the border rectangle with rounded corners
// Adjust the radius as needed
    final borderRect = RRect.fromRectAndCorners(
      scanWindow,
      topLeft: const Radius.circular(12.0),
      topRight: const Radius.circular(12.0),
      bottomLeft: const Radius.circular(12.0),
      bottomRight: const Radius.circular(12.0),
    );

    // Draw the white border
    canvas.drawPath(backgroundWithCutout, backgroundPaint);
    canvas.drawRRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
