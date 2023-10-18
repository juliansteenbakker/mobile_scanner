
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';

// void main() {
//   runApp(const AnalyzeView());
// }

// class AnalyzeView extends StatefulWidget {
//   const AnalyzeView({Key? key}) : super(key: key);

//   @override
//   _AnalyzeViewState createState() => _AnalyzeViewState();
// }

// class _AnalyzeViewState extends State<AnalyzeView>
//     with SingleTickerProviderStateMixin {
//   List<Offset> points = [];

//   // CameraController cameraController = CameraController(context, width: 320, height: 150);

//   String? barcode;

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         body: Builder(builder: (context) {
//           return Stack(
//             children: [
//               MobileScanner(
//                   // fitScreen: false,
//                   // controller: cameraController,
//                   onDetect: (barcode) {
//                 if (this.barcode != barcode.rawValue) {
//                   this.barcode = barcode.rawValue;
//                   if (barcode.corners != null) {
//                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                       content: Text(barcode.rawValue),
//                       duration: const Duration(milliseconds: 200),
//                       animation: null,
//                     ));
//                     setState(() {
//                       final List<Offset> points = [];
//                       // double factorWidth = args.size.width / 520;
//                       // double factorHeight = wanted / args.size.height;
//                       final size = MediaQuery.of(context).devicePixelRatio;
//                       debugPrint('Size: ${barcode.corners}');
//                       for (var point in barcode.corners!) {
//                         final adjustedWith = point.dx;
//                         final adjustedHeight = point.dy;
//                         points.add(
//                             Offset(adjustedWith / size, adjustedHeight / size));
//                         // points.add(Offset((point.dx ) / size,
//                         //     (point.dy) / size));
//                         // final differenceWidth = (args.wantedSize!.width - args.size.width) / 2;
//                         // final differenceHeight = (args.wantedSize!.height - args.size.height) / 2;
//                         // points.add(Offset((point.dx + differenceWidth) / size,
//                         //     (point.dy + differenceHeight) / size));
//                       }
//                       this.points = points;
//                     });
//                   }
//                 }
//                 // Default 640 x480
//               }),
//               CustomPaint(
//                 painter: OpenPainter(points),
//               ),
//               // Container(
//               //   alignment: Alignment.bottomCenter,
//               //   margin: EdgeInsets.only(bottom: 80.0),
//               //   child: IconButton(
//               //     icon: ValueListenableBuilder(
//               //       valueListenable: cameraController.torchState,
//               //       builder: (context, state, child) {
//               //         final color =
//               //             state == TorchState.off ? Colors.grey : Colors.white;
//               //         return Icon(Icons.bolt, color: color);
//               //       },
//               //     ),
//               //     iconSize: 32.0,
//               //     onPressed: () => cameraController.torch(),
//               //   ),
//               // ),
//             ],
//           );
//         }),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     // cameraController.dispose();
//     super.dispose();
//   }

//   void display(Barcode barcode) {
//     Navigator.of(context).popAndPushNamed('display', arguments: barcode);
//   }
// }

// class OpenPainter extends CustomPainter {
//   final List<Offset> points;

//   OpenPainter(this.points);
//   @override
//   void paint(Canvas canvas, Size size) {
//     var paint1 = Paint()
//       ..color = const Color(0xff63aa65)
//       ..strokeWidth = 10;
//     //draw points on canvas
//     canvas.drawPoints(PointMode.points, points, paint1);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }

// class OpacityCurve extends Curve {
//   @override
//   double transform(double t) {
//     if (t < 0.1) {
//       return t * 10;
//     } else if (t <= 0.9) {
//       return 1.0;
//     } else {
//       return (1.0 - t) * 10;
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/barcode_scanner_window.dart';
import 'package:mobile_scanner_example/scanner_error_widget.dart';

void main() {
  debugPaintSizeEnabled = false;
  runApp(HomePage());
}

class HomePage extends StatefulWidget {
  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: BarcodeScannerWithOverlay());
  }
}

class BarcodeScannerWithOverlay extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<BarcodeScannerWithOverlay> {
  String? qr;
  String overlayText = "Please scan QR Code";
  bool camState = false;
  late BarcodeCapture currentBarcodeCapture ;
  final MobileScannerController controller = MobileScannerController(
    facing: CameraFacing.back,
    autoStart: false
  );
  @override
  initState() {
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
    controller.dispose();
  }

  configureCameraSettings() {
    setState(() {
      camState = !camState;
      controller.start();
    });
  }

  onBarcodeDetect(BarcodeCapture barcodeCapture) {
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
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
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
                child: camState
                    ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                        child: MobileScanner(
                          fit: BoxFit.contain,
                          onDetect: (BarcodeCapture barcodeCapture) => {
                            onBarcodeDetect(barcodeCapture)

                        },
                        overlay: 
                      Positioned(
                         bottom: height * 0.2,
                        child:Opacity(opacity: 0.7, child:
                        Text(overlayText, style: const TextStyle(backgroundColor: Colors.black26, color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, overflow: TextOverflow.ellipsis,),
                        maxLines: 1,
                        )
                        ) ,
                        ),
                        
                        controller: controller,
                        scanWindow: scanWindow,
                         errorBuilder: (context, error, child) {
                    return ScannerErrorWidget(error: error);
                },
                        ),
                
                ),
                        CustomPaint(
                          painter:  ScannerOverlay(scanWindow),
                        ),
                        Positioned(
                          bottom: 0.07 * height,
                          left: 0.35 * width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(onPressed: ()=>{
                                controller.toggleTorch()
                              }, icon:  Icon(Icons.flashlight_on, color: controller.torchEnabled ? Colors.yellow : Colors.black,),),
                              IconButton(onPressed: ()=>{
                                controller.switchCamera()
                              }, icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white,)),
                            ],
                          ),
                        )
                      ],
                    )
                    : const Center(child: Text("Tap on Camera to activate QR Scanner"))),

          ],
        ),
      ),
      floatingActionButton: camState ? null : FloatingActionButton(
          child: Icon(
            Icons.camera_alt
          ),
          onPressed: () {
            configureCameraSettings();
          }),
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
    final borderRadius = BorderRadius.circular(12.0); // Adjust the radius as needed
    final borderRect = RRect.fromRectAndCorners(
      scanWindow,
      topLeft: Radius.circular(12.0),
      topRight: Radius.circular(12.0),
      bottomLeft: Radius.circular(12.0),
      bottomRight: Radius.circular(12.0),
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
