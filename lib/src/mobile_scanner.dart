// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/src/mobile_scanner_handler.dart';
// import 'package:mobile_scanner/src/objects/preview_details.dart';
//
// import 'mobile_scanner_preview.dart';
// import 'objects/barcode_formats.dart';
//
// typedef ErrorCallback = Widget Function(BuildContext context, Object? error);
//
// Text _defaultNotStartedBuilder(context) => const Text("Camera Loading ...");
// Text _defaultOffscreenBuilder(context) => const Text("Camera Paused.");
// Text _defaultOnError(BuildContext context, Object? error) {
//   debugPrint("Error reading from camera: $error");
//   return const Text("Error reading from camera...");
// }
//
// class MobileScanner extends StatefulWidget {
//   const MobileScanner(
//       {Key? key,
//       required this.qrCodeCallback,
//       this.child,
//       this.fit = BoxFit.cover,
//       WidgetBuilder? notStartedBuilder,
//       WidgetBuilder? offscreenBuilder,
//       ErrorCallback? onError,
//       this.formats,
//       this.rearLens = true,
//       this.manualFocus = false})
//       : notStartedBuilder = notStartedBuilder ?? _defaultNotStartedBuilder,
//         offscreenBuilder =
//             offscreenBuilder ?? notStartedBuilder ?? _defaultOffscreenBuilder,
//         onError = onError ?? _defaultOnError,
//         super(key: key);
//
//   final BoxFit fit;
//   final ValueChanged<String?> qrCodeCallback;
//   final Widget? child;
//   final WidgetBuilder notStartedBuilder;
//   final WidgetBuilder offscreenBuilder;
//   final ErrorCallback onError;
//   final List<BarcodeFormats>? formats;
//   final bool rearLens;
//   final bool manualFocus;
//
//   static void toggleFlash() {
//     MobileScannerHandler.toggleFlash();
//   }
//
//   static void flipCamera() {
//     MobileScannerHandler.switchCamera();
//   }
//
//   @override
//   _MobileScannerState createState() => _MobileScannerState();
// }
//
// class _MobileScannerState extends State<MobileScanner>
//     with WidgetsBindingObserver {
//
//   bool onScreen = true;
//   Future<PreviewDetails>? _previewDetails;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance!.addObserver(this);
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance!.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       setState(() => onScreen = true);
//     } else {
//       if (_previewDetails != null && onScreen) {
//         MobileScannerHandler.stop();
//       }
//       setState(() {
//         onScreen = false;
//         _previewDetails = null;
//       });
//     }
//   }
//
//   Future<PreviewDetails> _initPreview(num width, num height) async {
//     final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
//     return await MobileScannerHandler.start(
//       width: (devicePixelRatio * width.toInt()).ceil(),
//       height: (devicePixelRatio * height.toInt()).ceil(),
//       qrCodeHandler: widget.qrCodeCallback,
//       formats: widget.formats,
//     );
//   }
//
//   void switchCamera() {
//     MobileScannerHandler.rearLens = !MobileScannerHandler.rearLens;
//     restart();
//   }
//
//
//   void switchFocus() {
//     MobileScannerHandler.manualFocus = !MobileScannerHandler.manualFocus;
//     restart();
//   }
//
//   /// This method can be used to restart scanning
//   ///  the event that it was paused.
//   Future<void> restart() async {
//     await MobileScannerHandler.stop();
//     setState(() {
//       _previewDetails = null;
//     });
//   }
//
//   /// This method can be used to manually stop the
//   /// camera.
//   Future<void> stop() async {
//     await MobileScannerHandler.stop();
//   }
//
//   @override
//   deactivate() {
//     super.deactivate();
//     MobileScannerHandler.stop();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//         builder: (BuildContext context, BoxConstraints constraints) {
//       if (_previewDetails == null && onScreen) {
//         _previewDetails =
//             _initPreview(constraints.maxWidth, constraints.maxHeight);
//       } else if (!onScreen) {
//         return widget.offscreenBuilder(context);
//       }
//
//       return FutureBuilder(
//         future: _previewDetails,
//         builder: (BuildContext context, AsyncSnapshot<PreviewDetails> details) {
//           switch (details.connectionState) {
//             case ConnectionState.none:
//             case ConnectionState.waiting:
//               return widget.notStartedBuilder(context);
//             case ConnectionState.done:
//               if (details.hasError) {
//                 debugPrint(details.error.toString());
//                 return widget.onError(context, details.error);
//               }
//               Widget preview = SizedBox(
//                 width: constraints.maxWidth,
//                 height: constraints.maxHeight,
//                 child: Preview(
//                   previewDetails: details.data!,
//                   targetWidth: constraints.maxWidth,
//                   targetHeight: constraints.maxHeight,
//                   fit: widget.fit,
//                 ),
//               );
//
//               if (widget.child != null) {
//                 return Stack(
//                   children: [
//                     preview,
//                     widget.child!,
//                   ],
//                 );
//               }
//               return preview;
//
//             default:
//               throw AssertionError("${details.connectionState} not supported.");
//           }
//         },
//       );
//     });
//   }
// }
