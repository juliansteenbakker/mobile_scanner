import 'dart:ui';

import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';

/// This class defines the different start options for the mobile scanner.
class StartOptions {
  const StartOptions({
    required this.cameraDirection,
    required this.cameraResolution,
    required this.detectionSpeed,
    required this.detectionTimeoutMs,
    required this.formats,
    required this.returnImage,
    required this.torchEnabled,
    required this.useNewCameraSelector,
  });

  /// The direction for the camera.
  final CameraFacing cameraDirection;

  /// The desired camera resolution for the scanner.
  final Size? cameraResolution;

  /// The detection speed for the scanner.
  final DetectionSpeed detectionSpeed;

  /// The detection timeout for the scanner, in milliseconds.
  final int detectionTimeoutMs;

  /// The barcode formats to detect.
  final List<BarcodeFormat> formats;

  /// Whether the detected barcodes should provide their image data.
  final bool returnImage;

  /// Whether the torch should be turned on when the scanner starts.
  final bool torchEnabled;

  /// Whether the new resolution selector should be used.
  ///
  /// This option is only supported on Android. Other platforms will ignore this option.
  final bool useNewCameraSelector;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (cameraResolution != null)
        'cameraResolution': <int>[
          cameraResolution!.width.toInt(),
          cameraResolution!.height.toInt(),
        ],
      'facing': cameraDirection.rawValue,
      if (formats.isNotEmpty)
        'formats': formats.map((f) => f.rawValue).toList(),
      'returnImage': returnImage,
      'speed': detectionSpeed.rawValue,
      'timeout': detectionTimeoutMs,
      'torch': torchEnabled,
      'useNewCameraSelector': useNewCameraSelector,
    };
  }
}
