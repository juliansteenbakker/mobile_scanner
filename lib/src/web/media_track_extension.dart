import 'dart:js_interop';
import 'package:web/web.dart';

/// This extension provides nullable properties for [MediaTrackCapabilities],
/// for cases where the properties are not supported by all browsers.
extension NullableMediaTrackCapabilities on MediaTrackCapabilities {
  /// The `facingMode` property is not supported on Safari.
  @JS('facingMode')
  external JSArray<JSString>? get facingModeNullable;
}
