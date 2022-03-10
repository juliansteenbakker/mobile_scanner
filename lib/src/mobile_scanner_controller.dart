import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'objects/barcode_utility.dart';

/// The facing of a camera.
enum CameraFacing {
  /// Front facing camera.
  front,

  /// Back facing camera.
  back,
}

enum MobileScannerState { undetermined, authorized, denied }

/// The state of torch.
enum TorchState {
  /// Torch is off.
  off,

  /// Torch is on.
  on,
}

// enum AnalyzeMode { none, barcode }

class MobileScannerController {
  MethodChannel methodChannel =
      const MethodChannel('dev.steenbakker.mobile_scanner/scanner/method');
  EventChannel eventChannel =
      const EventChannel('dev.steenbakker.mobile_scanner/scanner/event');

  int? _controllerHashcode;
  StreamSubscription? events;

  final ValueNotifier<MobileScannerArguments?> args = ValueNotifier(null);
  final ValueNotifier<TorchState> torchState = ValueNotifier(TorchState.off);
  late final ValueNotifier<CameraFacing> cameraFacingState;
  final Ratio? ratio;
  final bool? torchEnabled;

  /// If provided, the scanner will only detect those specific formats.
  ///
  /// WARNING: On iOS, only 1 format is supported.
  final List<BarcodeFormat>? formats;

  CameraFacing facing;
  bool hasTorch = false;
  late StreamController<Barcode> barcodesController;

  Stream<Barcode> get barcodes => barcodesController.stream;

  MobileScannerController(
      {this.facing = CameraFacing.back,
      this.ratio,
      this.torchEnabled,
      this.formats}) {
    // In case a new instance is created before calling dispose()
    if (_controllerHashcode != null) {
      stop();
    }
    _controllerHashcode = hashCode;

    cameraFacingState = ValueNotifier(facing);

    // Sets analyze mode and barcode stream
    barcodesController = StreamController.broadcast(
        // onListen: () => setAnalyzeMode(AnalyzeMode.barcode.index),
        // onCancel: () => setAnalyzeMode(AnalyzeMode.none.index),
        );

    start();

    // Listen to events from the platform specific code
    events = eventChannel
        .receiveBroadcastStream()
        .listen((data) => handleEvent(data));
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
      case 'barcodeMac':
        barcodesController.add(Barcode(rawValue: data['payload']));
        break;
      case 'barcodeWeb':
        barcodesController.add(Barcode(rawValue: data));
        break;
      default:
        throw UnimplementedError();
    }
  }

  // TODO: Add more analyzers like text analyzer
  // void setAnalyzeMode(int mode) {
  //   if (hashCode != _controllerHashcode) {
  //     return;
  //   }
  //   methodChannel.invokeMethod('analyze', mode);
  // }

  // List<BarcodeFormats>? formats = _defaultBarcodeFormats,
  bool isStarting = false;

  /// Start barcode scanning. This will first check if the required permissions
  /// are set.
  Future<void> start() async {
    ensure('startAsync');
    if (isStarting) {
      throw Exception('mobile_scanner: Called start() while already starting.');
    }
    isStarting = true;
    // setAnalyzeMode(AnalyzeMode.barcode.index);

    // Check authorization status
    if (!kIsWeb) {
      MobileScannerState state =
          MobileScannerState.values[await methodChannel.invokeMethod('state')];
      switch (state) {
        case MobileScannerState.undetermined:
          final bool result = await methodChannel.invokeMethod('request');
          state = result
              ? MobileScannerState.authorized
              : MobileScannerState.denied;
          break;
        case MobileScannerState.denied:
          isStarting = false;
          throw PlatformException(code: 'NO ACCESS');
        case MobileScannerState.authorized:
          break;
      }
    }

    cameraFacingState.value = facing;

    // Set the starting arguments for the camera
    Map arguments = {};
    arguments['facing'] = facing.index;
    if (ratio != null) arguments['ratio'] = ratio;
    if (torchEnabled != null) arguments['torch'] = torchEnabled;

    if (formats != null) {
      if (Platform.isAndroid) {
        arguments['formats'] = formats!.map((e) => e.index).toList();
      } else if (Platform.isIOS || Platform.isMacOS) {
        arguments['formats'] = formats!.map((e) => e.rawValue).toList();
      }
    }

    // Start the camera with arguments
    Map<String, dynamic>? startResult = {};
    try {
      startResult = await methodChannel.invokeMapMethod<String, dynamic>(
          'start', arguments);
    } on PlatformException catch (error) {
      debugPrint('${error.code}: ${error.message}');
      isStarting = false;
      // setAnalyzeMode(AnalyzeMode.none.index);
      return;
    }

    if (startResult == null) {
      isStarting = false;
      throw PlatformException(code: 'INITIALIZATION ERROR');
    }

    hasTorch = startResult['torchable'];

    if (kIsWeb) {
      args.value = MobileScannerArguments(
          webId: startResult['ViewID'],
          size: Size(startResult['videoWidth'], startResult['videoHeight']),
          hasTorch: hasTorch);
    } else {
      args.value = MobileScannerArguments(
          textureId: startResult['textureId'],
          size: toSize(startResult['size']),
          hasTorch: hasTorch);
    }

    isStarting = false;
  }

  Future<void> stop() async {
    try {
      await methodChannel.invokeMethod('stop');
    } on PlatformException catch (error) {
      debugPrint('${error.code}: ${error.message}');
    }
  }

  /// Switches the torch on or off.
  ///
  /// Only works if torch is available.
  Future<void> toggleTorch() async {
    ensure('toggleTorch');
    if (!hasTorch) {
      debugPrint('Device has no torch/flash.');
      return;
    }

    TorchState state =
        torchState.value == TorchState.off ? TorchState.on : TorchState.off;

    try {
      await methodChannel.invokeMethod('torch', state.index);
    } on PlatformException catch (error) {
      debugPrint('${error.code}: ${error.message}');
    }
  }

  /// Switches the torch on or off.
  ///
  /// Only works if torch is available.
  Future<void> switchCamera() async {
    ensure('switchCamera');
    try {
      await methodChannel.invokeMethod('stop');
    } on PlatformException catch (error) {
      debugPrint(
          '${error.code}: camera is stopped! Please start before switching camera.');
      return;
    }
    facing =
        facing == CameraFacing.back ? CameraFacing.front : CameraFacing.back;
    await start();
  }

  /// Handles a local image file.
  /// Returns true if a barcode or QR code is found.
  /// Returns false if nothing is found.
  ///
  /// [path] The path of the image on the devices
  Future<bool> analyzeImage(String path) async {
    return await methodChannel.invokeMethod('analyzeImage', path);
  }

  /// Disposes the MobileScannerController and closes all listeners.
  void dispose() {
    if (hashCode == _controllerHashcode) {
      stop();
      events?.cancel();
      events = null;
      _controllerHashcode = null;
    }
    barcodesController.close();
  }

  /// Checks if the MobileScannerController is bound to the correct MobileScanner object.
  void ensure(String name) {
    final message =
        'MobileScannerController.$name called after MobileScannerController.dispose\n'
        'MobileScannerController methods should not be used after calling dispose.';
    assert(hashCode == _controllerHashcode, message);
  }
}
