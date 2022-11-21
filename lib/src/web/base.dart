import 'package:mobile_scanner/src/enums/camera_facing.dart';

abstract class WebBarcodeReaderBase {
  /// Timer used to capture frames to be analyzed
  final frameInterval = const Duration(milliseconds: 200);

  bool get isStarted;

  int get videoWidth;
  int get videoHeight;

  /// Starts streaming video
  Future<void> start({
    required String viewID,
    required CameraFacing cameraFacing,
  });

  /// Starts scanning QR codes or barcodes
  Stream<String?> detectBarcodeContinuously();

  /// Stops streaming video
  Future<void> stop();
}
