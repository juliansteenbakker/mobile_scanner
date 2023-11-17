import 'dart:js_interop';

/// The JS static interop class for the Result class in the ZXing library.
///
/// See also: https://github.com/zxing-js/library/blob/master/src/core/ResultPoint.ts
@JS()
@staticInterop
abstract class ResultPoint {}

extension ResultPointExt on ResultPoint {
  external JSFunction getX;

  external JSFunction getY;

  /// The x coordinate of the point.
  double get x {
    final JSNumber? x = getX.callAsFunction() as JSNumber?;

    return x?.toDartDouble ?? 0;
  }

  /// The y coordinate of the point.
  double get y {
    final JSNumber? y = getY.callAsFunction() as JSNumber?;

    return y?.toDartDouble ?? 0;
  }
}
