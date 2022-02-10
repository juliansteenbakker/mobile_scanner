import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'camera_args.dart';
import 'objects/barcode.dart';
import 'torch_state.dart';
import 'util.dart';

/// The facing of a camera.
enum CameraFacing {
  /// Front facing camera.
  front,

  /// Back facing camera.
  back,
}


/// A camera controller.
abstract class CameraController {
  /// Arguments for [CameraView].
  ValueNotifier<CameraArgs?> get args;

  /// Torch state of the camera.
  ValueNotifier<TorchState> get torchState;

  /// A stream of barcodes.
  Stream<Barcode> get barcodes;

  /// Create a [CameraController].
  ///
  /// [facing] target facing used to select camera.
  ///
  /// [formats] the barcode formats for image analyzer.
  factory CameraController([CameraFacing facing = CameraFacing.back]) =>
      _CameraController(facing);

  /// Start the camera asynchronously.
  Future<void> startAsync();

  /// Switch the torch's state.
  void torch();

  /// Release the resources of the camera.
  void dispose();
}

class _CameraController implements CameraController {
  static const MethodChannel method =
      MethodChannel('dev.steenbakker.mobile_scanner/scanner/method');
  static const EventChannel event =
      EventChannel('dev.steenbakker.mobile_scanner/scanner/event');

  static const undetermined = 0;
  static const authorized = 1;
  static const denied = 2;

  static const analyze_none = 0;
  static const analyze_barcode = 1;

  static int? id;
  static StreamSubscription? subscription;

  final CameraFacing facing;
  @override
  final ValueNotifier<CameraArgs?> args;
  @override
  final ValueNotifier<TorchState> torchState;

  bool torchable;
  late StreamController<Barcode> barcodesController;

  @override
  Stream<Barcode> get barcodes => barcodesController.stream;

  _CameraController(this.facing)
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
    startAsync();
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

  @override
  Future<void> startAsync() async {
    ensure('startAsync');
    // Check authorization state.
    var state = await method.invokeMethod('state');
    if (state == undetermined) {
      final result = await method.invokeMethod('request');
      state = result ? authorized : denied;
    }
    if (state != authorized) {
      throw PlatformException(code: 'NO ACCESS');
    }
    // Start camera.
    final answer =
        await method.invokeMapMethod<String, dynamic>('start', facing.index);
    final textureId = answer?['textureId'];
    final size = toSize(answer?['size']);
    args.value = CameraArgs(textureId, size);
    torchable = answer?['torchable'];
  }

  @override
  void torch() {
    ensure('torch');
    if (!torchable) {
      return;
    }
    var state =
        torchState.value == TorchState.off ? TorchState.on : TorchState.off;
    method.invokeMethod('torch', state.index);
  }

  @override
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
