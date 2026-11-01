import 'dart:js_interop';

import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:web/web.dart';

/// This extension provides a nullable [mediaDevices] property for [Navigator],
/// to handle non-secure contexts (HTTP) where [Navigator.mediaDevices]
/// is undefined.
extension NullableNavigatorMediaDevices on Navigator {
  /// The `mediaDevices` of the source device.
  @JS('mediaDevices')
  external MediaDevices? get mediaDevicesNullable;
}

/// This extension provides nullable properties for [MediaTrackCapabilities],
/// for cases where the properties are not supported by all browsers.
extension NullableMediaTrackCapabilities on MediaTrackCapabilities {
  /// The `facingMode` property is not supported on Safari.
  @JS('facingMode')
  external JSArray<JSString>? get facingModeNullable;

  /// The raw `torch` capability, as reported by the browser.
  ///
  /// Chromium and WebKit report a `boolean`, while the Image Capture
  /// specification changed this to `sequence<boolean>` in
  /// https://github.com/w3c/mediacapture-image/pull/305. Typed as [JSAny] so
  /// that either shape can be read; see [canEnableTorch].
  @JS('torch')
  external JSAny? get torchNullable;

  /// Whether the camera is able to turn its torch on.
  ///
  /// See [readTorchCapability].
  bool get canEnableTorch => readTorchCapability(torchNullable);
}

/// Whether [torch] reports that the camera can turn its torch on.
///
/// Accepts either shape of `MediaTrackCapabilities.torch`:
///
/// * a JS boolean, or
/// * a JS array of booleans, which is supported when the array contains
///   `true`.
///
/// JS `null` and `undefined` are unsupported. Any other shape throws a
/// [MobileScannerException].
bool readTorchCapability(JSAny? torch) {
  if (torch == null) {
    return false;
  }

  if (torch.isA<JSBoolean>()) {
    return (torch as JSBoolean).toDart;
  }

  if (torch.isA<JSArray<JSAny?>>()) {
    final values = (torch as JSArray<JSAny?>).toDart;

    if (values.every((value) => value.isA<JSBoolean>())) {
      return values.any((value) => (value! as JSBoolean).toDart);
    }
  }

  throw const MobileScannerException(
    errorCode: MobileScannerErrorCode.genericError,
    errorDetails: MobileScannerErrorDetails(
      message:
          'The browser reported the torch capability as neither a boolean '
          'nor a sequence of booleans. Please report the browser and its '
          'version at https://github.com/juliansteenbakker/mobile_scanner/issues.',
    ),
  );
}

/// This extension provides nullable properties for [MediaTrackSettings],
/// for cases where the properties are not supported by all browsers.
extension NullableMediaTrackSettings on MediaTrackSettings {
  /// The `facingMode` property is null on MacOS,
  /// even though the capability is supported.
  @JS('facingMode')
  external JSString? get facingModeNullable;

  /// The `deviceId` of the source device for this track.
  @JS('deviceId')
  external JSString? get deviceIdNullable;
}
