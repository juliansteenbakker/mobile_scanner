import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/utils/parse_device_orientation_extension.dart';

/// This class will manage the orientation corrections for textures
/// that are provided by the SurfaceProducer API on Android.
class AndroidSurfaceProducerDelegate {
  /// Construct a new [AndroidSurfaceProducerDelegate].
  AndroidSurfaceProducerDelegate({
    required this.cameraIsFrontFacing,
    required this.isPreviewPreTransformed,
    required this.naturalOrientation,
    required this.sensorOrientation,
  });

  /// Construct a new [AndroidSurfaceProducerDelegate]
  /// from the given [config] and [cameraDirection].
  ///
  /// Throws a [MobileScannerException] if the configuration is invalid.
  factory AndroidSurfaceProducerDelegate.fromConfiguration(
    Map<String, Object?> config,
    CameraFacing cameraDirection,
  ) {
    if (config
        case {
          'isPreviewPreTransformed': final bool isPreviewPreTransformed,
          'naturalDeviceOrientation': final String naturalDeviceOrientation,
          'sensorOrientation': final int sensorOrientation
        }) {
      final DeviceOrientation naturalOrientation =
          naturalDeviceOrientation.parseDeviceOrientation();

      return AndroidSurfaceProducerDelegate(
        cameraIsFrontFacing: cameraDirection == CameraFacing.front,
        isPreviewPreTransformed: isPreviewPreTransformed,
        naturalOrientation: naturalOrientation,
        sensorOrientation: sensorOrientation,
      );
    }

    throw const MobileScannerException(
      errorCode: MobileScannerErrorCode.genericError,
      errorDetails: MobileScannerErrorDetails(
        message: 'The start method did not return a valid configuration.',
      ),
    );
  }

  /// The rotation degrees corresponding to each device orientation.
  static const Map<DeviceOrientation, int> _degreesForDeviceOrientation =
      <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeRight: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeLeft: 270,
  };

  /// The subscription that listens to device orientation changes.
  StreamSubscription<Object?>? _deviceOrientationSubscription;

  /// Whether the current camera is a front facing camera.
  ///
  /// This is used to determine whether the orientation correction
  /// should apply an additional correction for front facing cameras.
  final bool cameraIsFrontFacing;

  /// The current orientation of the device.
  ///
  /// When the orientation changes this field is updated by notifications from
  /// the [_deviceOrientationSubscription].
  DeviceOrientation? currentDeviceOrientation;

  /// Whether the camera preview is pre-transformed,
  /// and thus does not need an orientation correction.
  final bool isPreviewPreTransformed;

  /// The initial orientation of the device, when the camera was started.
  ///
  /// The camera preview will use this orientation as the natural orientation
  /// to correct its rotation with respect to, if necessary.
  final DeviceOrientation naturalOrientation;

  /// The sensor orientation of the current camera, in degrees.
  final int sensorOrientation;

  /// Apply a rotation correction to the given [texture] widget.
  Widget applyRotationCorrection(Widget texture) {
    int naturalDeviceOrientationDegrees =
        _degreesForDeviceOrientation[naturalOrientation]!;

    if (isPreviewPreTransformed) {
      // If the camera preview is backed by a SurfaceTexture, the transformation
      // needed to correctly rotate the preview has already been applied.
      //
      // However, the camera preview rotation may need to be corrected if the
      // device is naturally landscape-oriented.
      if (naturalOrientation == DeviceOrientation.landscapeLeft ||
          naturalOrientation == DeviceOrientation.landscapeRight) {
        final int quarterTurns = (-naturalDeviceOrientationDegrees + 360) ~/ 4;

        return RotatedBox(
          quarterTurns: quarterTurns,
          child: texture,
        );
      }

      return texture;
    }

    // If the camera preview is not backed by a SurfaceTexture,
    // the camera preview rotation needs to be manually applied,
    // while also taking into account devices that are naturally landscape-oriented.
    final int signForCameraDirection = cameraIsFrontFacing ? 1 : -1;

    // For front-facing cameras, the preview is rotated counterclockwise,
    // so determine the rotation needed to correct the camera preview with
    // respect to the natural orientation of the device, based on the inverse of
    // of the natural orientation.
    if (signForCameraDirection == 1 &&
        (currentDeviceOrientation == DeviceOrientation.landscapeLeft ||
            currentDeviceOrientation == DeviceOrientation.landscapeRight)) {
      naturalDeviceOrientationDegrees += 180;
    }

    // See https://developer.android.com/media/camera/camera2/camera-preview#orientation_calculation
    final double rotation = (sensorOrientation +
            naturalDeviceOrientationDegrees * signForCameraDirection +
            360) %
        360;

    int quarterTurnsToCorrectPreview = rotation ~/ 90;

    // Correct the camera preview rotation for devices that are naturally landscape-oriented.
    if (naturalOrientation == DeviceOrientation.landscapeLeft ||
        naturalOrientation == DeviceOrientation.landscapeRight) {
      quarterTurnsToCorrectPreview +=
          (-naturalDeviceOrientationDegrees + 360) ~/ 4;
    }

    return RotatedBox(
      quarterTurns: quarterTurnsToCorrectPreview,
      child: texture,
    );
  }

  /// Start listening to device orientation changes,
  /// which are provided by the given [stream].
  void startListeningToDeviceOrientation(Stream<DeviceOrientation> stream) {
    _deviceOrientationSubscription ??=
        stream.listen((DeviceOrientation newOrientation) {
      currentDeviceOrientation = newOrientation;
    });
  }

  /// Dispose of this delegate.
  void dispose() {
    _deviceOrientationSubscription?.cancel();
    _deviceOrientationSubscription = null;
  }
}
