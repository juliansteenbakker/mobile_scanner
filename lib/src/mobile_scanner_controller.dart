import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/objects/barcode_utility.dart';

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

  //Must be static to keep the same value on new instances
  static int? _controllerHashcode;
  StreamSubscription? events;

  Function(bool permissionGranted)? onPermissionSet;
  final ValueNotifier<MobileScannerArguments?> args = ValueNotifier(null);
  final ValueNotifier<TorchState> torchState = ValueNotifier(TorchState.off);
  late final ValueNotifier<CameraFacing> cameraFacingState;
  final Ratio? ratio;
  final bool? torchEnabled;
  // Whether to return the image buffer with the Barcode event
  final bool returnImage;

  /// If provided, the scanner will only detect those specific formats.
  final List<BarcodeFormat>? formats;

  CameraFacing facing;
  bool hasTorch = false;
  late StreamController<Barcode> barcodesController;

  /// Whether to automatically resume the camera when the application is resumed
  bool autoResume;

  Stream<Barcode> get barcodes => barcodesController.stream;

  MobileScannerController({
    this.facing = CameraFacing.back,
    this.ratio,
    this.torchEnabled,
    this.formats,
    this.onPermissionSet,
    this.autoResume = true,
    this.returnImage = false,
  }) {
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

    // Listen to events from the platform specific code
    events = eventChannel
        .receiveBroadcastStream()
        .listen((data) => handleEvent(data as Map));
  }

  void handleEvent(Map event) {
    final name = event['name'];
    final data = event['data'];
    final binaryData = event['binaryData'];
    switch (name) {
      case 'torchState':
        final state = TorchState.values[data as int? ?? 0];
        torchState.value = state;
        break;
      case 'barcode':
        final image = returnImage ? event['image'] as Uint8List : null;
        final barcode = Barcode.fromNative(data as Map? ?? {}, image);
        barcodesController.add(barcode);
        break;
      case 'barcodeMac':
        barcodesController.add(
          Barcode(
            rawValue: (data as Map)['payload'] as String?,
          ),
        );
        break;
      case 'barcodeWeb':
        final bytes = (binaryData as List).cast<int>();
        barcodesController.add(
          Barcode(
            rawValue: data as String?,
            rawBytes: Uint8List.fromList(bytes),
          ),
        );
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
      MobileScannerState state = MobileScannerState
          .values[await methodChannel.invokeMethod('state') as int? ?? 0];
      switch (state) {
        case MobileScannerState.undetermined:
          final bool result =
              await methodChannel.invokeMethod('request') as bool? ?? false;
          state = result
              ? MobileScannerState.authorized
              : MobileScannerState.denied;
          onPermissionSet?.call(result);
          break;
        case MobileScannerState.denied:
          isStarting = false;
          onPermissionSet?.call(false);
          throw PlatformException(code: 'NO ACCESS');
        case MobileScannerState.authorized:
          onPermissionSet?.call(true);
          break;
      }
    }

    cameraFacingState.value = facing;

    // Set the starting arguments for the camera
    final Map arguments = {};
    arguments['facing'] = facing.index;
    /*    if (scanWindow != null) {
      arguments['scanWindow'] = [
        scanWindow!.left,
        scanWindow!.top,
        scanWindow!.right,
        scanWindow!.bottom,
      ];
    } */
    if (ratio != null) arguments['ratio'] = ratio;
    if (torchEnabled != null) arguments['torch'] = torchEnabled;

    if (formats != null) {
      if (Platform.isAndroid) {
        arguments['formats'] = formats!.map((e) => e.index).toList();
      } else if (Platform.isIOS || Platform.isMacOS) {
        arguments['formats'] = formats!.map((e) => e.rawValue).toList();
      }
    }
    arguments['returnImage'] = returnImage;

    // Start the camera with arguments
    Map<String, dynamic>? startResult = {};
    try {
      startResult = await methodChannel.invokeMapMethod<String, dynamic>(
        'start',
        arguments,
      );
    } on PlatformException catch (error) {
      debugPrint('${error.code}: ${error.message}');
      isStarting = false;
      if (error.code == "MobileScannerWeb") {
        onPermissionSet?.call(false);
      }
      // setAnalyzeMode(AnalyzeMode.none.index);
      return;
    }

    if (startResult == null) {
      isStarting = false;
      throw PlatformException(code: 'INITIALIZATION ERROR');
    }

    hasTorch = startResult['torchable'] as bool? ?? false;

    if (kIsWeb) {
      onPermissionSet?.call(
        true,
      ); // If we reach this line, it means camera permission has been granted

      args.value = MobileScannerArguments(
        webId: startResult['ViewID'] as String?,
        size: Size(
          startResult['videoWidth'] as double? ?? 0,
          startResult['videoHeight'] as double? ?? 0,
        ),
        hasTorch: hasTorch,
      );
    } else {
      args.value = MobileScannerArguments(
        textureId: startResult['textureId'] as int?,
        size: toSize(startResult['size'] as Map? ?? {}),
        hasTorch: hasTorch,
      );
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

    final TorchState state =
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
        '${error.code}: camera is stopped! Please start before switching camera.',
      );
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
    return methodChannel
        .invokeMethod<bool>('analyzeImage', path)
        .then<bool>((bool? value) => value ?? false);
  }

  /// Disposes the MobileScannerController and closes all listeners.
  void dispose() {
    if (hashCode == _controllerHashcode) {
      stop();
      events?.cancel();
      events = null;
      _controllerHashcode = null;
      onPermissionSet = null;
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

  /// updates the native scanwindow
  Future<void> updateScanWindow(Rect window) async {
    final data = [window.left, window.top, window.right, window.bottom];
    await methodChannel.invokeMethod('updateScanWindow', {'rect': data});
  }
}
