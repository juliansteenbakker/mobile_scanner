import 'dart:async';
import 'dart:io';
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_state.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/mobile_scanner_arguments.dart';

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
    @Deprecated(
      'Instead, use the result of calling `start()` to determine if permissions were granted.',
    )
    this.onPermissionSet,
    this.autoStart = true,
    this.cameraResolution,
    this.useNewCameraSelector = false,
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

  /// Sets the timeout, in milliseconds, of the scanner.
  ///
  /// This timeout is ignored if the [detectionSpeed]
  /// is not set to [DetectionSpeed.normal].
  ///
  /// By default this is set to `250` milliseconds,
  /// which prevents memory issues on older devices.
  final int detectionTimeoutMs;

  /// Automatically start the mobileScanner on initialization.
  final bool autoStart;

  /// The desired resolution for the camera.
  ///
  /// When this value is provided, the camera will try to match this resolution,
  /// or fallback to the closest available resolution.
  /// When this is null, Android defaults to a resolution of 640x480.
  ///
  /// Bear in mind that changing the resolution has an effect on the aspect ratio.
  ///
  /// When the camera orientation changes,
  /// the resolution will be flipped to match the new dimensions of the display.
  ///
  /// Currently only supported on Android.
  final Size? cameraResolution;

  /// Use the new resolution selector. Warning: not fully tested, may produce
  /// unwanted/zoomed images.
  ///
  /// Only supported on Android
  final bool useNewCameraSelector;

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

  /// A notifier that provides zoomScale.
  final ValueNotifier<double> zoomScaleState = ValueNotifier(0.0);

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
    arguments['facing'] = cameraFacingState.value.rawValue;
    arguments['torch'] = torchEnabled;
    arguments['speed'] = detectionSpeed.rawValue;
    arguments['timeout'] = detectionTimeoutMs;
    arguments['returnImage'] = returnImage;
    arguments['useNewCameraSelector'] = useNewCameraSelector;

    /*    if (scanWindow != null) {
      arguments['scanWindow'] = [
        scanWindow!.left,
        scanWindow!.top,
        scanWindow!.right,
        scanWindow!.bottom,
      ];
    } */

    if (formats != null) {
      if (kIsWeb || Platform.isIOS || Platform.isMacOS || Platform.isAndroid) {
        arguments['formats'] = formats!.map((e) => e.rawValue).toList();
      }
    }

    if (cameraResolution != null) {
      arguments['cameraResolution'] = <int>[
        cameraResolution!.width.toInt(),
        cameraResolution!.height.toInt(),
      ];
    }

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

    events ??= _eventChannel
        .receiveBroadcastStream()
        .listen((data) => _handleEvent(data as Map));

    isStarting = true;

    // Check authorization status
    if (!kIsWeb) {
      final MobileScannerState state;

      try {
        state = MobileScannerState.fromRawValue(
          await _methodChannel.invokeMethod('state') as int? ?? 0,
        );
      } on PlatformException catch (error) {
        isStarting = false;

        throw MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
          errorDetails: MobileScannerErrorDetails(
            code: error.code,
            details: error.details as Object?,
            message: error.message,
          ),
        );
      }

      switch (state) {
        // Android does not have an undetermined permission state.
        // So if the permission state is denied, just request it now.
        case MobileScannerState.undetermined:
        case MobileScannerState.denied:
          try {
            final bool granted =
                await _methodChannel.invokeMethod('request') as bool? ?? false;

            if (!granted) {
              isStarting = false;
              throw const MobileScannerException(
                errorCode: MobileScannerErrorCode.permissionDenied,
              );
            }
          } on PlatformException catch (error) {
            isStarting = false;
            throw MobileScannerException(
              errorCode: MobileScannerErrorCode.genericError,
              errorDetails: MobileScannerErrorDetails(
                code: error.code,
                details: error.details as Object?,
                message: error.message,
              ),
            );
          }

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

      final String? errorMessage = error.message;

      if (kIsWeb) {
        if (errorMessage == null) {
          errorCode = MobileScannerErrorCode.genericError;
        } else if (errorMessage.contains('NotFoundError') ||
            errorMessage.contains('NotSupportedError')) {
          errorCode = MobileScannerErrorCode.unsupported;
        } else if (errorMessage.contains('NotAllowedError')) {
          errorCode = MobileScannerErrorCode.permissionDenied;
        } else {
          errorCode = MobileScannerErrorCode.genericError;
        }
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

    final Size size;

    if (kIsWeb) {
      size = Size(
        startResult['videoWidth'] as double? ?? 0,
        startResult['videoHeight'] as double? ?? 0,
      );
    } else {
      final Map<Object?, Object?>? sizeInfo =
          startResult['size'] as Map<Object?, Object?>?;

      size = Size(
        sizeInfo?['width'] as double? ?? 0,
        sizeInfo?['height'] as double? ?? 0,
      );
    }

    isStarting = false;
    return startArguments.value = MobileScannerArguments(
      numberOfCameras: startResult['numberOfCameras'] as int?,
      size: size,
      hasTorch: hasTorch,
      textureId: kIsWeb ? null : startResult['textureId'] as int?,
      webId: kIsWeb ? startResult['ViewID'] as String? : null,
    );
  }

  /// Stops the camera, but does not dispose this controller.
  Future<void> stop() async {
    await _methodChannel.invokeMethod('stop');

    // After the camera stopped, set the torch state to off,
    // as the torch state callback is never called when the camera is stopped.
    torchState.value = TorchState.off;
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
    }

    if (!hasTorch) {
      return;
    }

    final TorchState newState =
        torchState.value == TorchState.off ? TorchState.on : TorchState.off;

    await _methodChannel.invokeMethod('torch', newState.rawValue);
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
    events ??= _eventChannel
        .receiveBroadcastStream()
        .listen((data) => _handleEvent(data as Map));

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

  /// Reset the zoomScale of the camera to use standard scale 1x.
  Future<void> resetZoomScale() async {
    await _methodChannel.invokeMethod('resetScale');
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
      case 'zoomScaleState':
        zoomScaleState.value = data as double? ?? 0.0;
      case 'barcode':
        if (data == null) return;
        final parsed = (data as List)
            .map((value) => Barcode.fromNative(value as Map))
            .toList();
        _barcodesController.add(
          BarcodeCapture(
            raw: data,
            barcodes: parsed,
            image: event['image'] as Uint8List?,
            width: event['width'] as double?,
            height: event['height'] as double?,
          ),
        );
      case 'barcodeMac':
        _barcodesController.add(
          BarcodeCapture(
            raw: data,
            barcodes: [
              Barcode(
                rawValue: (data as Map)['payload'] as String?,
                format: BarcodeFormat.fromRawValue(
                  data['symbology'] as int? ?? -1,
                ),
              ),
            ],
          ),
        );
      case 'barcodeWeb':
        final barcode = data as Map?;
        final corners = barcode?['corners'] as List<Object?>? ?? <Object?>[];

        _barcodesController.add(
          BarcodeCapture(
            raw: data,
            barcodes: [
              if (barcode != null)
                Barcode(
                  rawValue: barcode['rawValue'] as String?,
                  rawBytes: barcode['rawBytes'] as Uint8List?,
                  format: BarcodeFormat.fromRawValue(
                    barcode['format'] as int? ?? -1,
                  ),
                  corners: List.unmodifiable(
                    corners.cast<Map<Object?, Object?>>().map(
                      (Map<Object?, Object?> e) {
                        return Offset(e['x']! as double, e['y']! as double);
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
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
