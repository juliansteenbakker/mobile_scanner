import 'dart:async';
import 'dart:io';
// ignore: unnecessary_import
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/barcode_utility.dart';

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
    @Deprecated('Instead, use the result of calling `start()` to determine if permissions were granted.')
        this.onPermissionSet,
    this.autoStart = true,
  });

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

  /// Automatically start the mobileScanner on initialization.
  final bool autoStart;

  /// Sets the barcode stream
  final StreamController<BarcodeCapture> _barcodesController =
      StreamController.broadcast();
  Stream<BarcodeCapture> get barcodes => _barcodesController.stream;

  static const MethodChannel _methodChannel =
      MethodChannel('dev.steenbakker.mobile_scanner/scanner/method');
  static const EventChannel _eventChannel =
      EventChannel('dev.steenbakker.mobile_scanner/scanner/event');

  @Deprecated(
    'Instead, use the result of calling `start()` to determine if permissions were granted.',
  )
  Function(bool permissionGranted)? onPermissionSet;

  /// Listen to events from the platform specific code
  StreamSubscription? events;

  /// A notifier that provides several arguments about the MobileScanner
  final ValueNotifier<MobileScannerArguments?> startArguments =
      ValueNotifier(null);

  /// A notifier that provides the state of the Torch (Flash)
  final ValueNotifier<TorchState> torchState = ValueNotifier(TorchState.off);

  /// A notifier that provides the state of which camera is being used
  late final ValueNotifier<CameraFacing> cameraFacingState =
      ValueNotifier(facing);

  bool isStarting = false;

  /// A notifier that provides availability of the Torch (Flash)
  final ValueNotifier<bool?> hasTorchState = ValueNotifier(false);

  /// Returns whether the device has a torch.
  ///
  /// Throws an error if the controller is not initialized.
  bool get hasTorch {
    final hasTorch = hasTorchState.value;
    if (hasTorch == null) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerUninitialized,
      );
    }

    return hasTorch;
  }

  /// Set the starting arguments for the camera
  Map<String, dynamic> _argumentsToMap({CameraFacing? cameraFacingOverride}) {
    final Map<String, dynamic> arguments = {};

    cameraFacingState.value = cameraFacingOverride ?? facing;
    arguments['facing'] = cameraFacingState.value.index;
    arguments['torch'] = torchEnabled;
    arguments['speed'] = detectionSpeed.index;
    arguments['timeout'] = detectionTimeoutMs;

    /*    if (scanWindow != null) {
      arguments['scanWindow'] = [
        scanWindow!.left,
        scanWindow!.top,
        scanWindow!.right,
        scanWindow!.bottom,
      ];
    } */

    if (formats != null) {
      if (kIsWeb || Platform.isIOS || Platform.isMacOS) {
        arguments['formats'] = formats!.map((e) => e.rawValue).toList();
      } else if (Platform.isAndroid) {
        arguments['formats'] = formats!.map((e) => e.index).toList();
      }
    }
    arguments['returnImage'] = returnImage;
    return arguments;
  }

  /// Start scanning for barcodes.
  /// Upon calling this method, the necessary camera permission will be requested.
  ///
  /// Returns an instance of [MobileScannerArguments]
  /// when the scanner was successfully started.
  /// Returns null if the scanner is currently starting.
  ///
  /// Throws a [MobileScannerException] if starting the scanner failed.
  Future<MobileScannerArguments?> start({
    CameraFacing? cameraFacingOverride,
  }) async {
    if (isStarting) {
      debugPrint("Called start() while starting.");
      return null;
    }

    isStarting = true;

    events?.cancel();
    events = _eventChannel
        .receiveBroadcastStream()
        .listen((data) => _handleEvent(data as Map));

    // Check authorization status
    if (!kIsWeb) {
      final MobileScannerState state = MobileScannerState
          .values[await _methodChannel.invokeMethod('state') as int? ?? 0];
      switch (state) {
        case MobileScannerState.undetermined:
          bool result = false;

          try {
            result =
                await _methodChannel.invokeMethod('request') as bool? ?? false;
          } catch (error) {
            isStarting = false;
            throw const MobileScannerException(
              errorCode: MobileScannerErrorCode.genericError,
            );
          }

          if (!result) {
            isStarting = false;
            throw const MobileScannerException(
              errorCode: MobileScannerErrorCode.permissionDenied,
            );
          }

          break;
        case MobileScannerState.denied:
          isStarting = false;
          throw const MobileScannerException(
            errorCode: MobileScannerErrorCode.permissionDenied,
          );
        case MobileScannerState.authorized:
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
      MobileScannerErrorCode errorCode = MobileScannerErrorCode.genericError;

      if (error.code == "MobileScannerWeb") {
        errorCode = MobileScannerErrorCode.permissionDenied;
      }
      isStarting = false;

      throw MobileScannerException(
        errorCode: errorCode,
        errorDetails: MobileScannerErrorDetails(
          code: error.code,
          details: error.details as Object?,
          message: error.message,
        ),
      );
    }

    if (startResult == null) {
      isStarting = false;
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );
    }

    final hasTorch = startResult['torchable'] as bool? ?? false;
    hasTorchState.value = hasTorch;
    if (hasTorch && torchEnabled) {
      torchState.value = TorchState.on;
    }

    isStarting = false;
    return startArguments.value = MobileScannerArguments(
      size: kIsWeb
          ? Size(
              startResult['videoWidth'] as double? ?? 0,
              startResult['videoHeight'] as double? ?? 0,
            )
          : toSize(startResult['size'] as Map? ?? {}),
      hasTorch: hasTorch,
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
  /// Does nothing if the device has no torch.
  ///
  /// Throws if the controller was not initialized.
  Future<void> toggleTorch() async {
    final hasTorch = hasTorchState.value;

    if (hasTorch == null) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerUninitialized,
      );
    } else if (!hasTorch) {
      return;
    }

    torchState.value =
        torchState.value == TorchState.off ? TorchState.on : TorchState.off;

    await _methodChannel.invokeMethod('torch', torchState.value.index);
  }

  /// Changes the state of the camera (front or back).
  ///
  /// Does nothing if the device has no front camera.
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

  /// Set the zoomScale of the camera.
  ///
  /// [zoomScale] must be within 0.0 and 1.0, where 1.0 is the max zoom, and 0.0
  /// is zoomed out.
  Future<void> setZoomScale(double zoomScale) async {
    if (zoomScale < 0 || zoomScale > 1) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
        errorDetails: MobileScannerErrorDetails(
          message: 'The zoomScale must be between 0 and 1.',
        ),
      );
    }
    await _methodChannel.invokeMethod('setScale', zoomScale);
  }

  /// Disposes the MobileScannerController and closes all listeners.
  ///
  /// If you call this, you cannot use this controller object anymore.
  void dispose() {
    stop();
    events?.cancel();
    _barcodesController.close();
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
            width: event['width'] as double?,
            height: event['height'] as double?,
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
        final barcode = data as Map?;
        _barcodesController.add(
          BarcodeCapture(
            barcodes: [
              if (barcode != null)
                Barcode(
                  rawValue: barcode['rawValue'] as String?,
                  rawBytes: barcode['rawBytes'] as Uint8List?,
                  format: toFormat(barcode['format'] as int),
                ),
            ],
          ),
        );
        break;
      case 'error':
        throw MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
          errorDetails: MobileScannerErrorDetails(message: data as String?),
        );
      default:
        throw UnimplementedError(name as String?);
    }
  }

  /// updates the native ScanWindow
  Future<void> updateScanWindow(Rect? window) async {
    List? data;
    if (window != null) {
      data = [window.left, window.top, window.right, window.bottom];
    }

    await _methodChannel.invokeMethod('updateScanWindow', {'rect': data});
  }
}
