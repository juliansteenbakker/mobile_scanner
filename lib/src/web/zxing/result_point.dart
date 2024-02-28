import 'dart:js_interop';

/// The JS static interop class for the Result class in the ZXing library.
///
/// See also: https://github.com/zxing-js/library/blob/master/src/core/ResultPoint.ts
@JS()
@anonymous
@staticInterop
abstract class ResultPoint {}

extension ResultPointExt on ResultPoint {
  @JS('x')
  external JSNumber get _x;

  @JS('y')
  external JSNumber get _y;

  /// The x coordinate of the point.
  double get x => _x.toDartDouble;

  /// The y coordinate of the point.
  double get y => _y.toDartDouble;
}
