//TODO: Create example with scanner overlay

// import 'dart:ui';
//
// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
//
// void main() {
//   runApp(const AnalyzeView());
// }
//
// class AnalyzeView extends StatefulWidget {
//   const AnalyzeView({Key? key}) : super(key: key);
//
//   @override
//   _AnalyzeViewState createState() => _AnalyzeViewState();
// }
//
// class _AnalyzeViewState extends State<AnalyzeView>
//     with SingleTickerProviderStateMixin {
//   List<Offset> points = [];
//
//   // CameraController cameraController = CameraController(context, width: 320, height: 150);
//
//   String? barcode;
//
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
//                   onDetect: (barcode, args) {
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
//
//   @override
//   void dispose() {
//     // cameraController.dispose();
//     super.dispose();
//   }
//
//   void display(Barcode barcode) {
//     Navigator.of(context).popAndPushNamed('display', arguments: barcode);
//   }
// }
//
// class OpenPainter extends CustomPainter {
//   final List<Offset> points;
//
//   OpenPainter(this.points);
//   @override
//   void paint(Canvas canvas, Size size) {
//     var paint1 = Paint()
//       ..color = const Color(0xff63aa65)
//       ..strokeWidth = 10;
//     //draw points on canvas
//     canvas.drawPoints(PointMode.points, points, paint1);
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }
//
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
//
// // import 'package:flutter/material.dart';
// // import 'package:flutter/rendering.dart';
// // import 'package:mobile_scanner/mobile_scanner.dart';
// //
// // void main() {
// //   debugPaintSizeEnabled = false;
// //   runApp(HomePage());
// // }
// //
// // class HomePage extends StatefulWidget {
// //   @override
// //   HomeState createState() => HomeState();
// // }
// //
// // class HomeState extends State<HomePage> {
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(home: MyApp());
// //   }
// // }
// //
// // class MyApp extends StatefulWidget {
// //   @override
// //   _MyAppState createState() => _MyAppState();
// // }
// //
// // class _MyAppState extends State<MyApp> {
// //   String? qr;
// //   bool camState = false;
// //
// //   @override
// //   initState() {
// //     super.initState();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Plugin example app'),
// //       ),
// //       body: Center(
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.center,
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: <Widget>[
// //             Expanded(
// //                 child: camState
// //                     ? Center(
// //                   child: SizedBox(
// //                     width: 300.0,
// //                     height: 600.0,
// //                     child: MobileScanner(
// //                       onError: (context, error) => Text(
// //                         error.toString(),
// //                         style: TextStyle(color: Colors.red),
// //                       ),
// //                       qrCodeCallback: (code) {
// //                         setState(() {
// //                           qr = code;
// //                         });
// //                       },
// //                       child: Container(
// //                         decoration: BoxDecoration(
// //                           color: Colors.transparent,
// //                           border: Border.all(
// //                               color: Colors.orange,
// //                               width: 10.0,
// //                               style: BorderStyle.solid),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 )
// //                     : Center(child: Text("Camera inactive"))),
// //             Text("QRCODE: $qr"),
// //           ],
// //         ),
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //           child: Text(
// //             "press me",
// //             textAlign: TextAlign.center,
// //           ),
// //           onPressed: () {
// //             setState(() {
// //               camState = !camState;
// //             });
// //           }),
// //     );
// //   }
// // }
