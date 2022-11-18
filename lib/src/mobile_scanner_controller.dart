import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/barcode_utility.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';

/// The [MobileScannerController] holds all the logic of this plugin,
/// where as the [MobileScanner] class is the frontend of this plugin.
class MobileScannerController {
  MobileScannerController({
    this.facing = CameraFacing.back,
    this.detectionSpeed = DetectionSpeed.normal,
    this.detectionTimeoutMs = 250,
    this.torchEnabled = false,
    this.formats,
    this.returnImage = false,
    this.onPermissionSet,
  }) {
    // In case a new instance is created before calling dispose()
    if (controllerHashcode != null) {
      stop();
    }
    controllerHashcode = hashCode;
    events = _eventChannel
        .receiveBroadcastStream()
        .listen((data) => _handleEvent(data as Map));
  }

  /// The hashcode of the controller to check if the correct object is mounted.
  /// Must be static to keep the same value on new instances
  static int? controllerHashcode;

  /// Select which camera should be used.
  ///
  /// Default: CameraFacing.back
  final CameraFacing facing;

  /// Enable or disable the torch (Flash) on start
  ///
  /// Default: disabled
  final bool torchEnabled;

  /// Set to true if you want to return the image buffer with the Barcode event
  ///
  /// Only supported on iOS and Android
  final bool returnImage;

  /// If provided, the scanner will only detect those specific formats
  final List<BarcodeFormat>? formats;

  /// Sets the speed of detections.
  ///
  /// WARNING: DetectionSpeed.unrestricted can cause memory issues on some devices
  final DetectionSpeed detectionSpeed;

  /// Sets the timeout of scanner.
  /// The timeout is set in miliseconds.
  ///
  /// NOTE: The timeout only works if the [detectionSpeed] is set to
  /// [DetectionSpeed.normal] (which is the default value).
  final int detectionTimeoutMs;

  /// Sets the barcode stream
  final StreamController<BarcodeCapture> _barcodesController =
      StreamController.broadcast();
  Stream<BarcodeCapture> get barcodes => _barcodesController.stream;

  static const MethodChannel _methodChannel =
      MethodChannel('dev.steenbakker.mobile_scanner/scanner/method');
  static const EventChannel _eventChannel =
      EventChannel('dev.steenbakker.mobile_scanner/scanner/event');

  Function(bool permissionGranted)? onPermissionSet;

  /// Listen to events from the platform specific code
  late StreamSubscription events;

  /// A notifier that provides several arguments about the MobileScanner
  final ValueNotifier<MobileScannerArguments?> startArguments =
      ValueNotifier(null);

  /// A notifier that provides the state of the Torch (Flash)
  final ValueNotifier<TorchState> torchState = ValueNotifier(TorchState.off);

  /// A notifier that provides the state of which camera is being used
  late final ValueNotifier<CameraFacing> cameraFacingState =
      ValueNotifier(facing);

  bool isStarting = false;

  bool? _hasTorch;

  /// Set the starting arguments for the camera
  Map<String, dynamic> _argumentsToMap({CameraFacing? cameraFacingOverride}) {
    final Map<String, dynamic> arguments = {};

    cameraFacingState.value = cameraFacingOverride ?? facing;
    arguments['facing'] = cameraFacingState.value.index;
    arguments['torch'] = torchEnabled;
    arguments['speed'] = detectionSpeed.index;
    arguments['timeout'] = detectionTimeoutMs;

    if (formats != null) {
      if (Platform.isAndroid) {
        arguments['formats'] = formats!.map((e) => e.index).toList();
      } else if (Platform.isIOS || Platform.isMacOS) {
        arguments['formats'] = formats!.map((e) => e.rawValue).toList();
      }
    }
    arguments['returnImage'] = true;
    return arguments;
  }

  /// Start barcode scanning. This will first check if the required permissions
  /// are set.
  Future<MobileScannerArguments?> start({
    CameraFacing? cameraFacingOverride,
  }) async {
    if (isStarting) {
      debugPrint("Called start() while starting.");
      return null;
    }
    isStarting = true;

    // Check authorization status
    if (!kIsWeb) {
      final MobileScannerState state = MobileScannerState
          .values[await _methodChannel.invokeMethod('state') as int? ?? 0];
      switch (state) {
        case MobileScannerState.undetermined:
          final bool result =
              await _methodChannel.invokeMethod('request') as bool? ?? false;
          if (!result) {
            isStarting = false;
            onPermissionSet?.call(result);
            throw MobileScannerException('User declined camera permission.');
          }
          break;
        case MobileScannerState.denied:
          isStarting = false;
          onPermissionSet?.call(false);
          throw MobileScannerException('User declined camera permission.');
        case MobileScannerState.authorized:
          onPermissionSet?.call(true);
          break;
      }
    }

    // Start the camera with arguments
    Map<String, dynamic>? startResult = {};
    try {
      startResult = await _methodChannel.invokeMapMethod<String, dynamic>(
        'start',
        _argumentsToMap(cameraFacingOverride: cameraFacingOverride),
      );
    } on PlatformException catch (error) {
      debugPrint('${error.code}: ${error.message}');
      if (error.code == "MobileScannerWeb") {
        onPermissionSet?.call(false);
      }
      isStarting = false;
      return null;
    }

    if (startResult == null) {
      isStarting = false;
      throw MobileScannerException(
        'Failed to start mobileScanner, no response from platform side',
      );
    }

    _hasTorch = startResult['torchable'] as bool? ?? false;
    if (_hasTorch! && torchEnabled) {
      torchState.value = TorchState.on;
    }

    if (kIsWeb) {
      // If we reach this line, it means camera permission has been granted
      onPermissionSet?.call(
        true,
      );
    }

    isStarting = false;
    return startArguments.value = MobileScannerArguments(
      size: kIsWeb
          ? Size(
              startResult['videoWidth'] as double? ?? 0,
              startResult['videoHeight'] as double? ?? 0,
            )
          : toSize(startResult['size'] as Map? ?? {}),
      hasTorch: _hasTorch!,
      textureId: kIsWeb ? null : startResult['textureId'] as int?,
      webId: kIsWeb ? startResult['ViewID'] as String? : null,
    );
  }

  /// Stops the camera, but does not dispose this controller.
  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod('stop');
    } catch (e) {
      debugPrint('$e');
    }
  }

  /// Switches the torch on or off.
  ///
  /// Only works if torch is available.
  Future<void> toggleTorch() async {
    if (_hasTorch == null) {
      throw MobileScannerException(
        'Cannot toggle torch if start() has never been called',
      );
    } else if (!_hasTorch!) {
      throw MobileScannerException('Device has no torch');
    }

    torchState.value =
        torchState.value == TorchState.off ? TorchState.on : TorchState.off;

    await _methodChannel.invokeMethod('torch', torchState.value.index);
  }

  /// Switches the torch on or off.
  ///
  /// Only works if torch is available.
  Future<void> switchCamera() async {
    await _methodChannel.invokeMethod('stop');
    final CameraFacing facingToUse =
        cameraFacingState.value == CameraFacing.back
            ? CameraFacing.front
            : CameraFacing.back;
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
    _barcodesController.close();
    if (hashCode == controllerHashcode) {
      controllerHashcode = null;
      onPermissionSet = null;
    }
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
        if (data == null) return;
        final parsed = (data as List)
            .map((value) => Barcode.fromNative(value as Map))
            .toList();
        _barcodesController.add(
          BarcodeCapture(
            barcodes: parsed,
            image: event['image'] as Uint8List?,
          ),
        );
        break;
      case 'barcodeMac':
        _barcodesController.add(
          BarcodeCapture(
            barcodes: [
              Barcode(
                rawValue: (data as Map)['payload'] as String?,
              )
            ],
          ),
        );
        break;
      case 'barcodeWeb':
        _barcodesController.add(
          BarcodeCapture(
            barcodes: [
              Barcode(
                rawValue: data as String?,
              )
            ],
          ),
        );
        break;
      case 'error':
        throw MobileScannerException(data as String);
      default:
        throw UnimplementedError(name as String?);
    }
  }
}
