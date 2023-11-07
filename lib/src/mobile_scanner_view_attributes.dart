import 'dart:ui';

/// This interface defines the attributes for the mobile scanner view.
abstract class MobileScannerViewAttributes {
  /// Whether the current active camera has a torch.
  bool get hasTorch;

  /// The size of the camera output.
  Size get size;
}
