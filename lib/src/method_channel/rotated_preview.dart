import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';

/// This widget represents a camera preview that rotates itself,
/// based on changes in the device orientation.
final class RotatedPreview extends StatefulWidget {
  /// Construct a new [RotatedPreview] instance.
  const RotatedPreview({
    required this.child,
    required this.deviceOrientationStream,
    required this.facingSign,
    required this.initialDeviceOrientation,
    required this.sensorOrientationDegrees,
    super.key,
  });

  /// Construct a new [RotatedPreview] instance, from the given [cameraFacingDirection].
  factory RotatedPreview.fromCameraDirection(
    CameraFacing cameraFacingDirection, {
    required Widget child,
    required Stream<DeviceOrientation> deviceOrientationStream,
    required DeviceOrientation initialDeviceOrientation,
    required double sensorOrientationDegrees,
    Key? key,
  }) {
    final int facingSignForDirection = switch (cameraFacingDirection) {
      CameraFacing.front => 1,
      CameraFacing.back => -1,
      CameraFacing.unknown => 1,
      CameraFacing.external => 1,
    };

    return RotatedPreview(
      deviceOrientationStream: deviceOrientationStream,
      facingSign: facingSignForDirection,
      initialDeviceOrientation: initialDeviceOrientation,
      sensorOrientationDegrees: sensorOrientationDegrees,
      key: key,
      child: child,
    );
  }

  /// The preview widget to rotate.
  ///
  /// This is typically a [Texture] widget.
  final Widget child;

  /// The stream that provides updates to the device orientation.
  final Stream<DeviceOrientation> deviceOrientationStream;

  /// The facing sign for the camera facing direction.
  final int facingSign;

  /// The initial device orientation when this [RotatedPreview] widget is created.
  final DeviceOrientation initialDeviceOrientation;

  /// The orientation of the camera sensor on the device, in degrees.
  final double sensorOrientationDegrees;

  @override
  State<RotatedPreview> createState() => _RotatedPreviewState();
}

final class _RotatedPreviewState extends State<RotatedPreview> {
  /// The current device orientation.
  late DeviceOrientation deviceOrientation;

  /// The subscription for the device orientation stream.
  StreamSubscription<Object?>? _deviceOrientationSubscription;

  /// Compute the rotation correction for the preview.
  ///
  /// See also: https://developer.android.com/media/camera/camera2/camera-preview#orientation_calculation
  double _computeRotation(
    DeviceOrientation orientation, {
    required double sensorOrientationDegrees,
    required int sign,
  }) {
    final double deviceOrientationDegrees = switch (orientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeRight => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeLeft => 270,
    };

    return (sensorOrientationDegrees - deviceOrientationDegrees * sign + 360) %
        360;
  }

  @override
  void initState() {
    super.initState();

    deviceOrientation = widget.initialDeviceOrientation;
    _deviceOrientationSubscription = widget.deviceOrientationStream.listen((
      DeviceOrientation event,
    ) {
      if (!mounted || deviceOrientation == event) {
        return;
      }

      setState(() {
        deviceOrientation = event;
      });
    });
  }

  @override
  void dispose() {
    unawaited(_deviceOrientationSubscription?.cancel());
    _deviceOrientationSubscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double rotation = _computeRotation(
      deviceOrientation,
      sensorOrientationDegrees: widget.sensorOrientationDegrees,
      sign: widget.facingSign,
    );

    return RotatedBox(quarterTurns: rotation ~/ 90, child: widget.child);
  }
}
