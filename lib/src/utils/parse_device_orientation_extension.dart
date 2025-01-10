import 'package:flutter/services.dart';

/// This extension defines a utility function for parsing a [DeviceOrientation]
/// from a [String].
extension ParseDeviceOrientation on String {
  /// Parse `this` into a [DeviceOrientation].
  ///
  /// Returns the parsed device orientation,
  /// or null if `this` is not a valid device orientation.
  DeviceOrientation? tryParseDeviceOrientation() {
    return switch (this) {
      'PORTRAIT_UP' => DeviceOrientation.portraitUp,
      'PORTRAIT_DOWN' => DeviceOrientation.portraitDown,
      'LANDSCAPE_LEFT' => DeviceOrientation.landscapeLeft,
      'LANDSCAPE_RIGHT' => DeviceOrientation.landscapeRight,
      _ => null,
    };
  }
}
