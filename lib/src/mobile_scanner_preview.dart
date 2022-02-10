import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/src/objects/preview_details.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class Preview extends StatefulWidget {
  final double width, height;
  final double targetWidth, targetHeight;
  final int? textureId;
  final int? sensorOrientation;
  final BoxFit fit;

  Preview({
    Key? key,
    required PreviewDetails previewDetails,
    required this.targetWidth,
    required this.targetHeight,
    required this.fit,
  })  : textureId = previewDetails.textureId,
        width = previewDetails.width!.toDouble(),
        height = previewDetails.height!.toDouble(),
        sensorOrientation = previewDetails.sensorOrientation as int?,
        super(key: key);

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  bool landscapeLeft = false;

  @override
  void initState() {
    super.initState();
    _streamSubscriptions.add(
      magnetometerEvents.listen(
            (MagnetometerEvent event) {
              if (event.x <= 0) {
                landscapeLeft = true;
              } else {
                landscapeLeft = false;
              }
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }


  int _getRotationCompensation(NativeDeviceOrientation nativeOrientation) {
    int nativeRotation = 0;
    switch (nativeOrientation) {
      case NativeDeviceOrientation.portraitUp:
        nativeRotation = 0;
        break;
      case NativeDeviceOrientation.landscapeRight:
        nativeRotation = 90;
        break;
      case NativeDeviceOrientation.portraitDown:
        nativeRotation = 180;
        break;
      case NativeDeviceOrientation.landscapeLeft:
        nativeRotation = 270;
        break;
      case NativeDeviceOrientation.unknown:
      default:
        break;
    }

    return ((nativeRotation - widget.sensorOrientation! + 450) % 360) ~/ 90;
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    double frameHeight = widget.width;
    double frameWidth = widget.height;

    return ClipRect(
      child: FittedBox(
        fit: widget.fit,
        child: RotatedBox(
          quarterTurns: orientation == Orientation.landscape ? landscapeLeft ? 1 : 3 : 0,
          child: SizedBox(
            width: frameWidth,
            height: frameHeight,
            child: Texture(textureId: widget.textureId!),
          ),
        ),
      ),
    );

    return NativeDeviceOrientationReader(
      builder: (context) {
        var nativeOrientation =
            NativeDeviceOrientationReader.orientation(context);

        double frameHeight = widget.width;
        double frameWidth = widget.height;

        return ClipRect(
          child: FittedBox(
            fit: widget.fit,
            child: RotatedBox(
              quarterTurns: _getRotationCompensation(nativeOrientation),
              child: SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: Texture(textureId: widget.textureId!),
              ),
            ),
          ),
        );
      },
    );
  }
}
