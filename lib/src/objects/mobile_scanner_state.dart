import 'dart:ui';

import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';

/// This class represents the current state of a [MobileScannerController].
class MobileScannerState {
  /// Create a new [MobileScannerState] instance.
  const MobileScannerState({
    required this.availableCameras,
    required this.cameraDirection,
    required this.isInitialized,
    required this.isRunning,
    required this.size,
    required this.torchState,
    required this.zoomScale,
    this.error,
  });

  /// Create a new [MobileScannerState] instance that is uninitialized.
  const MobileScannerState.uninitialized(CameraFacing facing)
      : this(
          availableCameras: null,
          cameraDirection: facing,
          isInitialized: false,
          isRunning: false,
          size: Size.zero,
          torchState: TorchState.unavailable,
          zoomScale: 1.0,
        );

  /// The number of available cameras.
  ///
  /// This is null if the number of cameras is unknown.
  final int? availableCameras;

  /// The facing direction of the camera.
  final CameraFacing cameraDirection;

  /// The error that occurred while setting up or using the camera.
  final MobileScannerException? error;

  /// Whether the mobile scanner has initialized successfully.
  ///
  /// This is `true` if the camera is ready to be used.
  final bool isInitialized;

  /// Whether the mobile scanner is currently running.
  ///
  /// This is `true` if the camera is active.
  final bool isRunning;

  /// The size of the camera output.
  final Size size;

  /// The current state of the flashlight of the camera.
  final TorchState torchState;

  /// The current zoom scale of the camera.
  final double zoomScale;

  /// Create a copy of this state with the given parameters.
  MobileScannerState copyWith({
    int? availableCameras,
    CameraFacing? cameraDirection,
    MobileScannerException? error,
    bool? isInitialized,
    bool? isRunning,
    Size? size,
    TorchState? torchState,
    double? zoomScale,
  }) {
    return MobileScannerState(
      availableCameras: availableCameras ?? this.availableCameras,
      cameraDirection: cameraDirection ?? this.cameraDirection,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      isRunning: isRunning ?? this.isRunning,
      size: size ?? this.size,
      torchState: torchState ?? this.torchState,
      zoomScale: zoomScale ?? this.zoomScale,
    );
  }
}
