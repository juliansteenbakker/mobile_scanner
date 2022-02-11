import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'mobile_scanner_arguments.dart';
import 'objects/barcode.dart';
import 'objects/barcode_utility.dart';

/// The facing of a camera.
enum CameraFacing {
  /// Front facing camera.
  front,

  /// Back facing camera.
  back,
}

enum MobileScannerState {
  undetermined,
  authorized,
  denied
}

/// The state of torch.
enum TorchState {
  /// Torch is off.
  off,

  /// Torch is on.
  on,
}



// /// A camera controller.
// abstract class CameraController {
//   /// Arguments for [CameraView].
//   ValueNotifier<CameraArgs?> get args;
//
//   /// Torch state of the camera.
//   ValueNotifier<TorchState> get torchState;
//
//   /// A stream of barcodes.
//   Stream<Barcode> get barcodes;
//
//   /// Create a [CameraController].
//   ///
//   /// [facing] target facing used to select camera.
//   ///
//   /// [formats] the barcode formats for image analyzer.
//   factory CameraController([CameraFacing facing = CameraFacing.back] ) =>
//       _CameraController(facing);
//
//   /// Start the camera asynchronously.
//   Future<void> start();
//
//   /// Switch the torch's state.
//   void torch();
//
//   /// Release the resources of the camera.
//   void dispose();
// }

class MobileScannerController {

  static const MethodChannel method =
      MethodChannel('dev.steenbakker.mobile_scanner/scanner/method');
  static const EventChannel event =
      EventChannel('dev.steenbakker.mobile_scanner/scanner/event');



  static const analyze_none = 0;
  static const analyze_barcode = 1;

  static int? id;
  static StreamSubscription? subscription;

  final CameraFacing facing;
  final ValueNotifier<MobileScannerArguments?> args;
  final ValueNotifier<TorchState> torchState;

  bool torchable;
  late StreamController<Barcode> barcodesController;

  Stream<Barcode> get barcodes => barcodesController.stream;

  MobileScannerController(BuildContext context, {required num width, required num height, this.facing = CameraFacing.back})
      : args = ValueNotifier(null),
        torchState = ValueNotifier(TorchState.off),
        torchable = false {
    // In case new instance before dispose.
    if (id != null) {
      stop();
    }
    id = hashCode;
    // Create barcode stream controller.
    barcodesController = StreamController.broadcast(
      onListen: () => tryAnalyze(analyze_barcode),
      onCancel: () => tryAnalyze(analyze_none),
    );

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;


    start(
        width: (devicePixelRatio * width.toInt()).ceil(),
    height: (devicePixelRatio * height.toInt()).ceil());
    // Listen event handler.
    subscription =
        event.receiveBroadcastStream().listen((data) => handleEvent(data));
  }

  void handleEvent(Map<dynamic, dynamic> event) {
    final name = event['name'];
    final data = event['data'];
    switch (name) {
      case 'torchState':
        final state = TorchState.values[data];
        torchState.value = state;
        break;
      case 'barcode':
        final barcode = Barcode.fromNative(data);
        barcodesController.add(barcode);
        break;
      default:
        throw UnimplementedError();
    }
  }

  void tryAnalyze(int mode) {
    if (hashCode != id) {
      return;
    }
    method.invokeMethod('analyze', mode);
  }

  Future<void> start({
    int? width,
    int? height,
    // List<BarcodeFormats>? formats = _defaultBarcodeFormats,
  }) async {
    ensure('startAsync');
    // Check authorization state.
    MobileScannerState state = MobileScannerState.values[await method.invokeMethod('state')];
    switch (state) {
      case MobileScannerState.undetermined:
        final bool result = await method.invokeMethod('request');
        state = result ? MobileScannerState.authorized : MobileScannerState.denied;
        break;
      case MobileScannerState.authorized:
        break;
      case MobileScannerState.denied:
        throw PlatformException(code: 'NO ACCESS');
    }

    debugPrint('TARGET RESOLUTION $width, $height');
    // Start camera.
    final answer =
        await method.invokeMapMethod<String, dynamic>('start', {
          'targetWidth': width,
          'targetHeight': height,
          'facing': facing.index
        });
    final textureId = answer?['textureId'];
    final Size size = toSize(answer?['size']);
    debugPrint('RECEIVED SIZE: ${size.width} ${size.height}');
    if (width != null && height != null) {
      args.value = MobileScannerArguments(textureId: textureId, size: size, wantedSize: Size(width.toDouble(), height.toDouble()));
    } else {
      args.value = MobileScannerArguments(textureId: textureId, size: size);
    }

    torchable = answer?['torchable'];
  }

  void torch() {
    ensure('torch');
    if (!torchable) return;
    var state =
        torchState.value == TorchState.off ? TorchState.on : TorchState.off;
    method.invokeMethod('torch', state.index);
  }

  void dispose() {
    if (hashCode == id) {
      stop();
      subscription?.cancel();
      subscription = null;
      id = null;
    }
    barcodesController.close();
  }

  void stop() => method.invokeMethod('stop');

  void ensure(String name) {
    final message =
        'CameraController.$name called after CameraController.dispose\n'
        'CameraController methods should not be used after calling dispose.';
    assert(hashCode == id, message);
  }
}
