/// @docImport 'package:mobile_scanner/src/mobile_scanner.dart';
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/mobile_scanner_state.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';

/// The controller for the [MobileScanner] widget.
class MobileScannerController extends ValueNotifier<MobileScannerState> {
  /// Construct a new [MobileScannerController] instance.
  MobileScannerController({
    this.autoStart = true,
    this.cameraResolution,
    this.detectionSpeed = DetectionSpeed.normal,
    int detectionTimeoutMs = 250,
    this.facing = CameraFacing.back,
    this.formats = const <BarcodeFormat>[],
    this.returnImage = false,
    this.torchEnabled = false,
    this.invertImage = false,
    this.autoZoom = false,
    this.initialZoom = 1,
  }) : detectionTimeoutMs =
           detectionSpeed == DetectionSpeed.normal ? detectionTimeoutMs : 0,
       assert(
         detectionTimeoutMs >= 0,
         'The detection timeout must be greater than or equal to 0.',
       ),
       assert(
         facing != CameraFacing.unknown,
         'CameraFacing.unknown is not a valid camera direction.',
       ),
       super(const MobileScannerState.uninitialized());

  /// The desired resolution for the camera.
  ///
  /// When this value is provided, the camera will try to match this resolution,
  /// or fallback to the closest available resolution.
  /// When this is null, Android defaults to a resolution of 640x480.
  ///
  /// Bear in mind that changing the resolution has an effect on the aspect
  /// ratio.
  ///
  /// When the camera orientation changes,
  /// the resolution will be flipped to match the new dimensions of the display.
  ///
  /// Currently only supported on Android.
  final Size? cameraResolution;

  /// Automatically start the scanner on initialization.
  final bool autoStart;

  /// The detection speed for the scanner.
  ///
  /// Defaults to [DetectionSpeed.normal].
  final DetectionSpeed detectionSpeed;

  /// The detection timeout, in milliseconds, for the scanner.
  ///
  /// This timeout is ignored if the [detectionSpeed]
  /// is not set to [DetectionSpeed.normal].
  ///
  /// By default this is set to `250` milliseconds,
  /// which prevents memory issues on older devices.
  final int detectionTimeoutMs;

  /// The facing direction for the camera.
  ///
  /// Defaults to the back-facing camera.
  final CameraFacing facing;

  /// The formats that the scanner should detect.
  ///
  /// If this is empty, all supported formats are detected.
  final List<BarcodeFormat> formats;

  /// Whether the [BarcodeCapture.image] bytes should be provided.
  ///
  /// If this is false, [BarcodeCapture.image] will always be null.
  ///
  /// Defaults to false, and is only supported on iOS, MacOS and Android.
  final bool returnImage;

  /// Invert image colors for analyzer to support white-on-black barcodes, which
  /// are not supported by MLKit. Usage of this parameter can incur a
  /// performance cost, as frames need to be altered during processing.
  ///
  /// Defaults to false and is only supported on Android.
  final bool invertImage;

  /// Whether the flashlight should be turned on when the camera is started.
  ///
  /// Defaults to false.
  final bool torchEnabled;

  /// Whether the camera should auto zoom if the detected code is to far from
  /// the camera.
  ///
  /// Only supported on Android.
  final bool autoZoom;

  /// The initial zoom scale for the camera.
  ///
  /// Defaults to no initial zoom and is only supported on iOS, MacOS and
  /// Android.
  final double initialZoom;

  /// The internal barcode controller, that listens for detected barcodes.
  final StreamController<BarcodeCapture> _barcodesController =
      StreamController.broadcast();

  /// Get the stream of scanned barcodes.
  ///
  /// If an error occurred during the detection of a barcode,
  /// a [MobileScannerBarcodeException] error is emitted to the stream.
  Stream<BarcodeCapture> get barcodes => _barcodesController.stream;

  StreamSubscription<BarcodeCapture?>? _barcodesSubscription;
  StreamSubscription<TorchState>? _torchStateSubscription;
  StreamSubscription<double>? _zoomScaleSubscription;
  StreamSubscription<DeviceOrientation>? _deviceOrientationSubscription;

  bool _isDisposed = false;
  // This completer keeps track of whether the MobileScanner widget,
  // that is attached to this controller,
  // called its `initState()` lifecycle method.
  final Completer<void> _isAttachedCompleter = Completer<void>();

  void _disposeListeners() {
    unawaited(_barcodesSubscription?.cancel());
    unawaited(_torchStateSubscription?.cancel());
    unawaited(_zoomScaleSubscription?.cancel());
    unawaited(_deviceOrientationSubscription?.cancel());

    _barcodesSubscription = null;
    _torchStateSubscription = null;
    _zoomScaleSubscription = null;
    _deviceOrientationSubscription = null;
  }

  void _setupListeners() {
    _barcodesSubscription = MobileScannerPlatform.instance.barcodesStream
        .listen(
          (BarcodeCapture? barcode) {
            if (_barcodesController.isClosed || barcode == null) {
              return;
            }

            _barcodesController.add(barcode);
          },
          onError: (Object error) {
            if (_barcodesController.isClosed) {
              return;
            }

            _barcodesController.addError(error);
          },
          // Errors are handled gracefully by forwarding them.
          cancelOnError: false,
        );

    _torchStateSubscription = MobileScannerPlatform.instance.torchStateStream
        .listen((TorchState torchState) {
          if (_isDisposed) {
            return;
          }

          value = value.copyWith(torchState: torchState);
        });

    _zoomScaleSubscription = MobileScannerPlatform.instance.zoomScaleStateStream
        .listen((double zoomScale) {
          if (_isDisposed) {
            return;
          }

          value = value.copyWith(zoomScale: zoomScale);
        });

    if (MobileScannerPlatform.instance
        case final MethodChannelMobileScanner implementation
        when defaultTargetPlatform != TargetPlatform.macOS) {
      _deviceOrientationSubscription = implementation
          .deviceOrientationChangedStream
          .listen((DeviceOrientation orientation) {
            if (_isDisposed) {
              return;
            }

            value = value.copyWith(deviceOrientation: orientation);
          });
    }
  }

  void _throwIfNotInitialized() {
    if (!value.isInitialized) {
      throw MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerUninitialized,
        errorDetails: MobileScannerErrorDetails(
          message: MobileScannerErrorCode.controllerUninitialized.message,
        ),
      );
    }

    if (_isDisposed) {
      throw MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerDisposed,
        errorDetails: MobileScannerErrorDetails(
          message: MobileScannerErrorCode.controllerDisposed.message,
        ),
      );
    }
  }

  /// Returns false if stop is called but not necessary, otherwise true is
  /// returned.
  bool _stop() {
    // Do nothing if not initialized or already stopped.
    // On the web, the permission popup triggers a lifecycle change from resumed
    // to inactive,
    // due to the permission popup gaining focus.
    // This would 'stop' the camera while it is not ready yet.
    if (!value.isInitialized || !value.isRunning || _isDisposed) {
      return false;
    }

    _disposeListeners();

    final TorchState oldTorchState = value.torchState;

    // After the camera stopped, set the torch state to off,
    // as the torch state callback is never called when the camera is stopped.
    // If the device does not have a torch, do not report "off".
    value = value.copyWith(
      isRunning: false,
      torchState:
          oldTorchState == TorchState.unavailable
              ? TorchState.unavailable
              : TorchState.off,
    );
    return true;
  }

  /// Analyze an image file.
  ///
  /// The [path] points to a file on the device.
  /// The [formats] specify the barcode formats that should be detected in the
  /// image.
  /// If the [formats] are omitted or empty, all formats are detected.
  ///
  /// This is only supported on Android, physical iOS devices and MacOS.
  /// This is not supported on the iOS Simulator, due to restrictions on the
  /// Simulator.
  ///
  /// Returns the [BarcodeCapture] that was found in the image.
  ///
  /// If an error occurred during the analysis of the image,
  /// a [MobileScannerBarcodeException] error is thrown.
  ///
  /// If analyzing images from a file is not supported, an [UnsupportedError]
  /// is thrown.
  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) {
    return MobileScannerPlatform.instance.analyzeImage(path, formats: formats);
  }

  /// Build a camera preview widget.
  Widget buildCameraView() {
    _throwIfNotInitialized();

    return MobileScannerPlatform.instance.buildCameraView();
  }

  /// Reset the zoom scale of the camera.
  ///
  /// Does nothing if the camera is not running.
  Future<void> resetZoomScale() async {
    _throwIfNotInitialized();

    if (!value.isRunning) {
      return;
    }

    // When the platform has updated the zoom scale,
    // it will send an update through the zoom scale state event stream.
    await MobileScannerPlatform.instance.resetZoomScale();
  }

  /// Set the zoom scale of the camera.
  ///
  /// The [zoomScale] must be between 0.0 and 1.0 (both inclusive).
  ///
  /// If the [zoomScale] is out of range,
  /// it is adjusted to fit within the allowed range.
  ///
  /// Does nothing if the camera is not running.
  Future<void> setZoomScale(double zoomScale) async {
    _throwIfNotInitialized();

    if (!value.isRunning) {
      return;
    }

    final double clampedZoomScale = zoomScale.clamp(0.0, 1.0);

    // Update the zoom scale state to the new state.
    // When the platform has updated the zoom scale,
    // it will send an update through the zoom scale state event stream.
    await MobileScannerPlatform.instance.setZoomScale(clampedZoomScale);
  }

  /// Set the focus point for the camera.
  ///
  /// The [position] must be a point between `0,0` and `1,1`, both inclusive.
  ///
  /// Does nothing if the camera is not running.
  Future<void> setFocusPoint(Offset position) async {
    _throwIfNotInitialized();

    if (!value.isRunning) {
      return;
    }

    final Offset clampedPosition = Offset(
      position.dx.clamp(0, 1),
      position.dy.clamp(0, 1),
    );

    await MobileScannerPlatform.instance.setFocusPoint(clampedPosition);
  }

  /// Start scanning for barcodes.
  ///
  /// The [cameraDirection] can be used to specify the camera direction.
  /// If this is null, this defaults to the [facing] value.
  ///
  /// Does nothing if the camera is already running.
  /// Upon calling this method, the necessary camera permission will be
  /// requested.
  ///
  /// If the permission is denied on iOS, MacOS or Web, there is no way to
  /// request it again.
  Future<void> start({CameraFacing? cameraDirection}) async {
    if (_isDisposed) {
      throw MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerDisposed,
        errorDetails: MobileScannerErrorDetails(
          message: MobileScannerErrorCode.controllerDisposed.message,
        ),
      );
    }

    // If start was called before the MobileScanner widget
    // had a chance to call its initState method,
    // wait for it to be called, using a timeout.
    if (!_isAttachedCompleter.isCompleted) {
      // The timeout is currently an arbitrary value,
      // which should be long enough for the next frame
      // to propagate any pending changes to the widget tree.
      await _isAttachedCompleter.future
          .timeout(const Duration(milliseconds: 500))
          .catchError((Object error, StackTrace stackTrace) {
            throw MobileScannerException(
              errorCode: MobileScannerErrorCode.controllerNotAttached,
              errorDetails: MobileScannerErrorDetails(
                message: MobileScannerErrorCode.controllerNotAttached.message,
                details: stackTrace.toString(),
              ),
            );
          });

      // Abort if the controller was disposed
      // while waiting for the widget to be attached.
      if (_isDisposed) {
        throw MobileScannerException(
          errorCode: MobileScannerErrorCode.controllerDisposed,
          errorDetails: MobileScannerErrorDetails(
            message: MobileScannerErrorCode.controllerDisposed.message,
          ),
        );
      }
    }

    if (cameraDirection == CameraFacing.unknown) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
        errorDetails: MobileScannerErrorDetails(
          message: 'CameraFacing.unknown is not a valid camera direction.',
        ),
      );
    }

    // Do nothing if the camera is already running.
    if (value.isRunning) {
      return;
    }

    if (value.isStarting) {
      throw MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerInitializing,
        errorDetails: MobileScannerErrorDetails(
          message: MobileScannerErrorCode.controllerInitializing.message,
        ),
      );
    }

    if (!_isDisposed) {
      value = value.copyWith(isStarting: true);
    }

    final StartOptions options = StartOptions(
      cameraDirection: cameraDirection ?? facing,
      cameraResolution: cameraResolution,
      detectionSpeed: detectionSpeed,
      detectionTimeoutMs: detectionTimeoutMs,
      formats: formats,
      returnImage: returnImage,
      torchEnabled: torchEnabled,
      invertImage: invertImage,
      autoZoom: autoZoom,
      initialZoom: initialZoom,
    );

    try {
      _setupListeners();

      final MobileScannerViewAttributes viewAttributes =
          await MobileScannerPlatform.instance.start(options);

      if (!_isDisposed) {
        value = value.copyWith(
          availableCameras: viewAttributes.numberOfCameras,
          cameraDirection: viewAttributes.cameraDirection,
          isInitialized: true,
          isStarting: false,
          isRunning: true,
          size: viewAttributes.size,
          deviceOrientation: viewAttributes.initialDeviceOrientation,
          // Provide the current torch state.
          // Updates are provided by the `torchStateStream`.
          torchState: viewAttributes.currentTorchMode,
        );
      }
    } on MobileScannerException catch (error) {
      // The initialization finished with an error.
      // To avoid stale values, reset the camera direction,
      // output size, torch state and zoom scale to the defaults.
      if (!_isDisposed) {
        value = value.copyWith(
          cameraDirection: CameraFacing.unknown,
          isInitialized: true,
          isStarting: false,
          isRunning: false,
          error: error,
          size: Size.zero,
          torchState: TorchState.unavailable,
          zoomScale: 1,
        );
      }
    }
  }

  /// Stop the camera.
  ///
  /// After calling this method, the camera can be restarted using [start].
  ///
  /// Does nothing if the camera is already stopped.
  Future<void> stop() async {
    if (_stop()) {
      await MobileScannerPlatform.instance.stop();
    }
  }

  /// Pause the camera.
  ///
  /// This method stops to update camera frame and scan barcodes.
  /// After calling this method, the camera can be restarted using [start].
  ///
  /// Does nothing if the camera is already paused or stopped.
  Future<void> pause() async {
    if (_stop()) {
      await MobileScannerPlatform.instance.pause();
    }
  }

  /// Switch between the front and back camera.
  ///
  /// Does nothing if the device has less than 2 cameras,
  /// or if the current camera is an external camera.
  Future<void> switchCamera() async {
    _throwIfNotInitialized();

    final int? availableCameras = value.availableCameras;
    final CameraFacing cameraDirection = value.cameraDirection;

    // Do nothing if the amount of cameras is less than 2 cameras.
    // If the the current platform does not provide the amount of cameras,
    // continue anyway.
    if (availableCameras != null && availableCameras < 2) {
      return;
    }

    // If the camera direction is not known,
    // or if the camera is an external camera, do not allow switching cameras.
    if (cameraDirection == CameraFacing.unknown ||
        cameraDirection == CameraFacing.external) {
      return;
    }

    await stop();

    switch (value.cameraDirection) {
      case CameraFacing.front:
        return start(cameraDirection: CameraFacing.back);
      case CameraFacing.back:
        return start(cameraDirection: CameraFacing.front);
      case CameraFacing.external:
      case CameraFacing.unknown:
        return;
    }
  }

  /// Switches the flashlight on or off.
  ///
  /// Does nothing if the device has no torch,
  /// or if the camera is not running.
  ///
  /// If the current torch state is [TorchState.auto],
  /// the torch is turned on or off depending on its actual current state.
  Future<void> toggleTorch() async {
    _throwIfNotInitialized();

    if (!value.isRunning) {
      return;
    }

    final TorchState torchState = value.torchState;

    if (torchState == TorchState.unavailable) {
      return;
    }

    // Request the torch state to be switched to the opposite state.
    // When the platform has updated the torch state,
    // it will send an update through the torch state event stream.
    await MobileScannerPlatform.instance.toggleTorch();
  }

  /// Update the scan window with the given [window] rectangle.
  ///
  /// If [window] is null, the scan window will be reset to the full camera
  /// preview.
  Future<void> updateScanWindow(Rect? window) async {
    if (_isDisposed || !value.isInitialized) {
      return;
    }

    await MobileScannerPlatform.instance.updateScanWindow(window);
  }

  /// Dispose the controller.
  ///
  /// Once the controller is disposed, it cannot be used anymore.
  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    unawaited(_barcodesController.close());
    super.dispose();

    await MobileScannerPlatform.instance.dispose();
  }

  /// Signal to this [MobileScannerController] that it is attached
  /// to a [MobileScanner] widget.
  ///
  /// This method is called by `_MobileScannerState.initState()`
  /// and is not intended to be used directly.
  @internal
  void attach() {
    if (_isAttachedCompleter.isCompleted) {
      return;
    }

    _isAttachedCompleter.complete();
  }
}
