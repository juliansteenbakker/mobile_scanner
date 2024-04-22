import 'dart:js_interop';
import 'package:web/web.dart';

/// This extension provides nullable properties for [MediaStreamTrack],
/// for cases where the properties are not supported by all browsers.
extension NullableMediaStreamTrackCapabilities on MediaStreamTrack {
  /// The `getCapabilities` function is not supported on Firefox.
  @JS('getCapabilities')
  external JSFunction? get getCapabilitiesNullable;
}

/// This extension provides nullable properties for [MediaTrackCapabilities],
/// for cases where the properties are not supported by all browsers.
extension NullableMediaTrackCapabilities on MediaTrackCapabilities {
  /// The `facingMode` property is not supported on Safari.
  @JS('facingMode')
  external JSArray<JSString>? get facingModeNullable;
}
