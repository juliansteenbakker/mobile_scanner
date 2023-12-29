import 'dart:ui';

/// This class defines the attributes for the mobile scanner view.
class MobileScannerViewAttributes {
  const MobileScannerViewAttributes({
    required this.hasTorch,
    this.numberOfCameras,
    required this.size,
  });

  /// Whether the current active camera has a torch.
  final bool hasTorch;

  /// The number of available cameras.
  final int? numberOfCameras;

  /// The size of the camera output.
  final Size size;
}
