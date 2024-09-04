import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
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
    this.useNewCameraSelector = false,
  })  : detectionTimeoutMs =
            detectionSpeed == DetectionSpeed.normal ? detectionTimeoutMs : 0,
        assert(
          detectionTimeoutMs >= 0,
          'The detection timeout must be greater than or equal to 0.',
        ),
        super(MobileScannerState.uninitialized(facing));

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

  /// Whether scanned barcodes should contain the image
  /// that is embedded into the barcode.
  ///
  /// If this is false, [BarcodeCapture.image] will always be null.
  ///
  /// Defaults to false, and is only supported on iOS, MacOS and Android.
  final bool returnImage;

  /// Whether the flashlight should be turned on when the camera is started.
  ///
  /// Defaults to false.
  final bool torchEnabled;

  /// Use the new resolution selector.
  ///
  /// This feature is experimental and not fully tested yet.
  /// Use caution when using this flag,
  /// as the new resolution selector may produce unwanted or zoomed images.
  ///
  /// Only supported on Android.
  final bool useNewCameraSelector;

  /// The internal barcode controller, that listens for detected barcodes.
  final StreamController<BarcodeCapture> _barcodesController =
      StreamController.broadcast();

  /// Get the stream of scanned barcodes.
  Stream<BarcodeCapture> get barcodes => _barcodesController.stream;

  StreamSubscription<BarcodeCapture?>? _barcodesSubscription;
  StreamSubscription<TorchState>? _torchStateSubscription;
  StreamSubscription<double>? _zoomScaleSubscription;

  bool _isDisposed = false;

  void _disposeListeners() {
    _barcodesSubscription?.cancel();
    _torchStateSubscription?.cancel();
    _zoomScaleSubscription?.cancel();

    _barcodesSubscription = null;
    _torchStateSubscription = null;
    _zoomScaleSubscription = null;
  }

  void _setupListeners() {
    _barcodesSubscription = MobileScannerPlatform.instance.barcodesStream
        .listen((BarcodeCapture? barcode) {
      if (_barcodesController.isClosed || barcode == null) {
        return;
      }

      _barcodesController.add(barcode);
    });

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
  }

  void _throwIfNotInitialized() {
    if (!value.isInitialized) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerUninitialized,
        errorDetails: MobileScannerErrorDetails(
          message: 'The MobileScannerController has not been initialized.',
        ),
      );
    }

    if (_isDisposed) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerDisposed,
        errorDetails: MobileScannerErrorDetails(
          message:
              'The MobileScannerController was used after it has been disposed.',
        ),
      );
    }
  }

  /// Analyze an image file.
  ///
  /// The [path] points to a file on the device.
  ///
  /// This is only supported on Android and iOS.
  ///
  /// Returns the [BarcodeCapture] that was found in the image.
  Future<BarcodeCapture?> analyzeImage(String path) {
    return MobileScannerPlatform.instance.analyzeImage(path);
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

  /// Start scanning for barcodes.
  ///
  /// The [cameraDirection] can be used to specify the camera direction.
  /// If this is null, this defaults to the [facing] value.
  ///
  /// Does nothing if the camera is already running.
  /// Upon calling this method, the necessary camera permission will be requested.
  ///
  /// If the permission is denied on iOS, MacOS or Web, there is no way to request it again.
  Future<void> start({CameraFacing? cameraDirection}) async {
    if (_isDisposed) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerDisposed,
        errorDetails: MobileScannerErrorDetails(
          message:
              'The MobileScannerController was used after it has been disposed.',
        ),
      );
    }

    // Permission was denied, do nothing.
    // When the controller is stopped,
    // the error is reset so the permission can be requested again if possible.
    if (value.error?.errorCode == MobileScannerErrorCode.permissionDenied) {
      return;
    }

    // Do nothing if the camera is already running.
    if (value.isRunning) {
      return;
    }

    final CameraFacing effectiveDirection = cameraDirection ?? facing;

    final StartOptions options = StartOptions(
      cameraDirection: effectiveDirection,
      cameraResolution: cameraResolution,
      detectionSpeed: detectionSpeed,
      detectionTimeoutMs: detectionTimeoutMs,
      formats: formats,
      returnImage: returnImage,
      torchEnabled: torchEnabled,
      useNewCameraSelector: useNewCameraSelector,
    );

    try {
      _setupListeners();

      final MobileScannerViewAttributes viewAttributes =
          await MobileScannerPlatform.instance.start(
        options,
      );

      if (!_isDisposed) {
        value = value.copyWith(
          availableCameras: viewAttributes.numberOfCameras,
          cameraDirection: effectiveDirection,
          isInitialized: true,
          isRunning: true,
          size: viewAttributes.size,
          // Provide the current torch state.
          // Updates are provided by the `torchStateStream`.
          torchState: viewAttributes.currentTorchMode,
        );
      }
    } on MobileScannerException catch (error) {
      // The initialization finished with an error.
      // To avoid stale values, reset the output size,
      // torch state and zoom scale to the defaults.
      if (!_isDisposed) {
        value = value.copyWith(
          cameraDirection: facing,
          isInitialized: true,
          isRunning: false,
          error: error,
          size: Size.zero,
          torchState: TorchState.unavailable,
          zoomScale: 1.0,
        );
      }
    } on PermissionRequestPendingException catch (_) {
      // If a permission request was already pending, do nothing.
    }
  }

  /// Stop the camera.
  ///
  /// After calling this method, the camera can be restarted using [start].
  ///
  /// Does nothing if the camera is already stopped.
  Future<void> stop() async {
    // Do nothing if not initialized or already stopped.
    // On the web, the permission popup triggers a lifecycle change from resumed to inactive,
    // due to the permission popup gaining focus.
    // This would 'stop' the camera while it is not ready yet.
    if (!value.isInitialized || !value.isRunning || _isDisposed) {
      return;
    }

    _disposeListeners();

    final TorchState oldTorchState = value.torchState;

    // After the camera stopped, set the torch state to off,
    // as the torch state callback is never called when the camera is stopped.
    // If the device does not have a torch, do not report "off".
    value = value.copyWith(
      isRunning: false,
      torchState: oldTorchState == TorchState.unavailable
          ? TorchState.unavailable
          : TorchState.off,
    );

    await MobileScannerPlatform.instance.stop();
  }

  /// Switch between the front and back camera.
  ///
  /// Does nothing if the device has less than 2 cameras.
  Future<void> switchCamera() async {
    _throwIfNotInitialized();

    final int? availableCameras = value.availableCameras;

    // Do nothing if the amount of cameras is less than 2 cameras.
    // If the the current platform does not provide the amount of cameras,
    // continue anyway.
    if (availableCameras != null && availableCameras < 2) {
      return;
    }

    await stop();

    final CameraFacing cameraDirection = value.cameraDirection;

    await start(
      cameraDirection: cameraDirection == CameraFacing.front
          ? CameraFacing.back
          : CameraFacing.front,
    );
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
  /// If [window] is null, the scan window will be reset to the full camera preview.
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
}
