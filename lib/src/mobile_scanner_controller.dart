import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/objects/barcode_utility.dart';

/// The [MobileScannerController] holds all the logic of this plugin,
/// where as the [MobileScanner] class is the frontend of this plugin.
class MobileScannerController {
  MobileScannerController({
    this.facing = CameraFacing.back,
    this.ratio,
    this.torchEnabled = false,
    this.formats,
    this.autoResume = true,
    this.returnImage = false,
  });

  /// Select which camera should be used.
  ///
  /// Default: CameraFacing.back
  final CameraFacing facing;

  /// Analyze the image in 4:3 or 16:9
  ///
  /// Only on Android
  final Ratio? ratio;

  /// Enable or disable the torch (Flash)
  ///
  /// Default: disabled
  final bool torchEnabled;

  /// Set to true if you want to return the image buffer with the Barcode event
  ///
  /// Only supported on iOS and Android
  final bool returnImage;

  /// If provided, the scanner will only detect those specific formats
  ///
  /// WARNING: On iOS, only 1 format is supported
  final List<BarcodeFormat>? formats;

  /// Whether to automatically resume the camera when the application is resumed
  bool autoResume;

  /// Sets the barcode stream
  StreamController<Barcode> barcodesController = StreamController.broadcast();
  Stream<Barcode> get barcodes => barcodesController.stream;

  static const MethodChannel _methodChannel =
      MethodChannel('dev.steenbakker.mobile_scanner/scanner/method');
  static const EventChannel _eventChannel =
      EventChannel('dev.steenbakker.mobile_scanner/scanner/event');

  /// Listen to events from the platform specific code
  late final StreamSubscription events = _eventChannel
      .receiveBroadcastStream()
      .listen((data) => _handleEvent(data as Map));

  /// A notifier that provides several arguments about the MobileScanner
  final ValueNotifier<MobileScannerArguments?> arguments = ValueNotifier(null);

  /// A notifier that provides the state of the Torch (Flash)
  final ValueNotifier<TorchState> torchState = ValueNotifier(TorchState.off);

  /// A notifier that provides the state of which camera is being used
  late final ValueNotifier<CameraFacing> cameraFacingState =
      ValueNotifier(facing);

  bool isStarting = false;
  bool _hasTorch = false;

  /// Start barcode scanning. This will first check if the required permissions
  /// are set.
  Future<void> start({CameraFacing? cameraFacingOverride}) async {
    debugPrint('Hashcode controller: $hashCode');
    if (isStarting) {
      throw Exception('mobile_scanner: Called start() while already starting.');
    }
    isStarting = true;

    // Check authorization status
    if (!kIsWeb) {
      MobileScannerState state = MobileScannerState
          .values[await _methodChannel.invokeMethod('state') as int? ?? 0];
      switch (state) {
        case MobileScannerState.undetermined:
          final bool result =
              await _methodChannel.invokeMethod('request') as bool? ?? false;
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

    CameraFacing facingToUse = CameraFacing.back;

    if (cameraFacingOverride != null) {
      facingToUse = cameraFacingOverride;
    } else {
      facingToUse = facing;
    }

    cameraFacingState.value = facingToUse;

    // Set the starting arguments for the camera
    final Map startArguments = {};
    startArguments['facing'] = facingToUse.index;
    if (ratio != null) startArguments['ratio'] = ratio;
    startArguments['torch'] = torchEnabled;

    if (formats != null) {
      if (Platform.isAndroid) {
        startArguments['formats'] = formats!.map((e) => e.index).toList();
      } else if (Platform.isIOS || Platform.isMacOS) {
        startArguments['formats'] = formats!.map((e) => e.rawValue).toList();
      }
    }
    startArguments['returnImage'] = true;

    // Start the camera with arguments
    Map<String, dynamic>? startResult = {};
    try {
      startResult = await _methodChannel.invokeMapMethod<String, dynamic>(
        'start',
        startArguments,
      );
    } on PlatformException catch (error) {
      debugPrint('${error.code}: ${error.message}');
      isStarting = false;
      return;
    }

    if (startResult == null) {
      isStarting = false;
      throw PlatformException(code: 'INITIALIZATION ERROR');
    }

    _hasTorch = startResult['torchable'] as bool? ?? false;
    if (_hasTorch && torchEnabled) {
      torchState.value = TorchState.on;
    }

    if (kIsWeb) {
      arguments.value = MobileScannerArguments(
        webId: startResult['ViewID'] as String?,
        size: Size(
          startResult['videoWidth'] as double? ?? 0,
          startResult['videoHeight'] as double? ?? 0,
        ),
        hasTorch: _hasTorch,
      );
    } else {
      arguments.value = MobileScannerArguments(
        textureId: startResult['textureId'] as int?,
        size: toSize(startResult['size'] as Map? ?? {}),
        hasTorch: _hasTorch,
      );
    }

    isStarting = false;
  }

  /// Stops the camera, but does not dispose this controller.
  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod('stop');
    } on PlatformException catch (error) {
      debugPrint('${error.code}: ${error.message}');
    }
  }

  /// Switches the torch on or off.
  ///
  /// Only works if torch is available.
  Future<void> toggleTorch() async {
    if (!_hasTorch) {
      debugPrint('Device has no torch/flash.');
      return;
    }

    final TorchState state =
        torchState.value == TorchState.off ? TorchState.on : TorchState.off;

    try {
      await _methodChannel.invokeMethod('torch', state.index);
      torchState.value = state;
    } on PlatformException catch (error) {
      debugPrint('${error.code}: ${error.message}');
    }
  }

  /// Switches the torch on or off.
  ///
  /// Only works if torch is available.
  Future<void> switchCamera() async {
    try {
      await _methodChannel.invokeMethod('stop');
    } on PlatformException catch (error) {
      debugPrint(
        '${error.code}: camera is stopped! Please start before switching camera.',
      );
      return;
    }
    final CameraFacing facingToUse =
        facing == CameraFacing.back ? CameraFacing.front : CameraFacing.back;
    await start(cameraFacingOverride: facingToUse);
  }

  /// Handles a local image file.
  /// Returns true if a barcode or QR code is found.
  /// Returns false if nothing is found.
  ///
  /// [path] The path of the image on the devices
  Future<bool> analyzeImage(String path) async {
    return _methodChannel
        .invokeMethod<bool>('analyzeImage', path)
        .then<bool>((bool? value) => value ?? false);
  }

  /// Disposes the MobileScannerController and closes all listeners.
  ///
  /// If you call this, you cannot use this controller object anymore.
  void dispose() {
    stop();
    events.cancel();
    barcodesController.close();
  }

  /// Handles a returning event from the platform side
  void _handleEvent(Map event) {
    final name = event['name'];
    final data = event['data'];

    switch (name) {
      case 'torchState':
        final state = TorchState.values[data as int? ?? 0];
        torchState.value = state;
        break;
      case 'barcode':
        final barcode = Barcode.fromNative(
            data as Map? ?? {}, event['image'] as Uint8List?);
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
        barcodesController.add(Barcode(rawValue: data as String?));
        break;
      default:
        throw UnimplementedError();
    }
  }
}

enum Ratio { ratio_4_3, ratio_16_9 }

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
