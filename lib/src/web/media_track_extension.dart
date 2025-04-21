import 'dart:js_interop';
import 'package:web/web.dart';

/// This extension provides nullable properties for [MediaTrackCapabilities],
/// for cases where the properties are not supported by all browsers.
extension NullableMediaTrackCapabilities on MediaTrackCapabilities {
  /// The `facingMode` property is not supported on Safari.
  @JS('facingMode')
  external JSArray<JSString>? get facingModeNullable;
}

/// This extension provides nullable properties for [MediaTrackSettings],
/// for cases where the properties are not supported by all browsers.
extension NullableMediaTrackSettings on MediaTrackSettings {
  /// The `facingMode` property is null on MacOS,
  /// even though the capability is supported.
  @JS('facingMode')
  external JSString? get facingModeNullable;
}
