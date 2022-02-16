import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const AnalyzeView());
}

class AnalyzeView extends StatefulWidget {
  const AnalyzeView({Key? key}) : super(key: key);

  @override
  _AnalyzeViewState createState() => _AnalyzeViewState();
}

class _AnalyzeViewState extends State<AnalyzeView>
    with SingleTickerProviderStateMixin {
  String? barcode;

  MobileScannerController controller = MobileScannerController(
    torchEnabled: true,
    facing: CameraFacing.front,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Builder(builder: (context) {
          return Stack(
            children: [
              MobileScanner(
                  controller: controller,
                  fit: BoxFit.contain,
                  // controller: MobileScannerController(
                  //   torchEnabled: true,
                  //   facing: CameraFacing.front,
                  // ),
                  onDetect: (barcode, args) {
                    if (this.barcode != barcode.rawValue) {
                      setState(() {
                        this.barcode = barcode.rawValue;
                      });
                    }
                  }),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  alignment: Alignment.bottomCenter,
                  height: 100,
                  color: Colors.black.withOpacity(0.4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        color: Colors.white,
                        icon: ValueListenableBuilder(
                          valueListenable: controller.torchState,
                          builder: (context, state, child) {
                            switch (state as TorchState) {
                              case TorchState.off:
                                return const Icon(Icons.flash_off,
                                    color: Colors.grey);
                              case TorchState.on:
                                return const Icon(Icons.flash_on,
                                    color: Colors.yellow);
                            }
                          },
                        ),
                        iconSize: 32.0,
                        onPressed: () => controller.toggleTorch(),
                      ),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 120,
                          height: 50,
                          child: FittedBox(
                            child: Text(
                              barcode ?? 'Scan something!',
                              overflow: TextOverflow.fade,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline4!
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        color: Colors.white,
                        icon: ValueListenableBuilder(
                          valueListenable: controller.cameraFacingState,
                          builder: (context, state, child) {
                            if (state == CameraFacing.front) {
                              return const Icon(Icons.camera_front);
                            } else {
                              return const Icon(Icons.camera_rear);
                            }
                          },
                        ),
                        iconSize: 32.0,
                        onPressed: () => controller.switchCamera(),
                      ),
                    ],
                  ),
                ),
              ),

              // Container(
              //   alignment: Alignment.bottomCenter,
              //   margin: EdgeInsets.only(bottom: 80.0),
              //   child: IconButton(
              //     icon: ValueListenableBuilder(
              //       valueListenable: cameraController.torchState,
              //       builder: (context, state, child) {
              //         final color =
              //             state == TorchState.off ? Colors.grey : Colors.white;
              //         return Icon(Icons.bolt, color: color);
              //       },
              //     ),
              //     iconSize: 32.0,
              //     onPressed: () => cameraController.torch(),
              //   ),
              // ),
            ],
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    // cameraController.dispose();
    super.dispose();
  }

  void display(Barcode barcode) {
    Navigator.of(context).popAndPushNamed('display', arguments: barcode);
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
//
// void main() {
//   debugPaintSizeEnabled = false;
//   runApp(HomePage());
// }
//
// class HomePage extends StatefulWidget {
//   @override
//   HomeState createState() => HomeState();
// }
//
// class HomeState extends State<HomePage> {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(home: MyApp());
//   }
// }
//
// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   String? qr;
//   bool camState = false;
//
//   @override
//   initState() {
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Plugin example app'),
//       ),
//       body: Center(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Expanded(
//                 child: camState
//                     ? Center(
//                   child: SizedBox(
//                     width: 300.0,
//                     height: 600.0,
//                     child: MobileScanner(
//                       onError: (context, error) => Text(
//                         error.toString(),
//                         style: TextStyle(color: Colors.red),
//                       ),
//                       qrCodeCallback: (code) {
//                         setState(() {
//                           qr = code;
//                         });
//                       },
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.transparent,
//                           border: Border.all(
//                               color: Colors.orange,
//                               width: 10.0,
//                               style: BorderStyle.solid),
//                         ),
//                       ),
//                     ),
//                   ),
//                 )
//                     : Center(child: Text("Camera inactive"))),
//             Text("QRCODE: $qr"),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//           child: Text(
//             "press me",
//             textAlign: TextAlign.center,
//           ),
//           onPressed: () {
//             setState(() {
//               camState = !camState;
//             });
//           }),
//     );
//   }
// }
