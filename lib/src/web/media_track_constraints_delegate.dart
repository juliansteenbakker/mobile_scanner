import 'dart:js_interop';

import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:web/web.dart';

/// This class represents a delegate that manages the constraints for a [MediaStreamTrack].
final class MediaTrackConstraintsDelegate {
  /// Constructs a [MediaTrackConstraintsDelegate] instance.
  const MediaTrackConstraintsDelegate();

  /// Get the settings for the given [mediaStream].
  MediaTrackSettings? getSettings(MediaStream? mediaStream) {
    final List<JSAny?>? tracks = mediaStream?.getVideoTracks().toDart;

    if (tracks == null || tracks.isEmpty) {
      return null;
    }

    final MediaStreamTrack? track = tracks.first as MediaStreamTrack?;

    if (track == null) {
      return null;
    }

    final MediaTrackSettings settings = track.getSettings();

    return MediaTrackSettings(
      width: settings.width,
      height: settings.height,
      zoom: settings.zoomNullable ?? 1.0,
      facingMode: settings.facingModeNullable ?? '',
      focusMode: settings.focusModeNullable ?? 'none',
      torch: settings.torchNullable ?? false,
      focusDistance: settings.focusDistanceNullable ?? 0.0,
      aspectRatio: settings.aspectRatio,
    );
  }

  /// Returns a list of supported flashlight modes for the given [mediaStream].
  ///
  /// The [TorchState.off] mode is always supported, regardless of the return value.
  Future<List<TorchState>> getSupportedFlashlightModes(
    MediaStream? mediaStream,
  ) async {
    if (mediaStream == null) {
      return [];
    }

    final List<JSAny?> tracks = mediaStream.getVideoTracks().toDart;

    if (tracks.isEmpty) {
      return [];
    }

    final MediaStreamTrack? track = tracks.first as MediaStreamTrack?;

    if (track == null) {
      return [];
    }

    try {
      final MediaTrackCapabilities capabilities = track.getCapabilities();

      return [
        if (capabilities.torch) TorchState.on,
      ];
    } catch (_) {
      // Firefox does not support getCapabilities() yet.
      // https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/getCapabilities#browser_compatibility

      return [];
    }
  }

  /// Returns whether the given [mediaStream] has a flashlight.
  Future<bool> hasFlashlight(MediaStream? mediaStream) async {
    return (await getSupportedFlashlightModes(mediaStream)).isNotEmpty;
  }

  /// Set the flashlight state of the given [mediaStream] to the given [value].
  Future<void> setFlashlightState(
    MediaStream? mediaStream,
    TorchState value,
  ) async {
    if (mediaStream == null) {
      return;
    }

    if (await hasFlashlight(mediaStream)) {
      final List<JSAny?> tracks = mediaStream.getVideoTracks().toDart;

      if (tracks.isEmpty) {
        return;
      }

      final bool flashlightEnabled = switch (value) {
        TorchState.on => true,
        TorchState.off || TorchState.unavailable => false,
      };

      final MediaStreamTrack? track = tracks.first as MediaStreamTrack?;

      final MediaTrackConstraints constraints = MediaTrackConstraints(
        advanced: [
          {'torch': flashlightEnabled}.jsify(),
        ].toJS,
      );

      await track?.applyConstraints(constraints).toDart;
    }
  }
}

// TODO: turn this extension into an extension type when Dart 3.3 releases.

// This extension exists because the Web IDL bindings for MediaTrackSettings
// do not account for unavailable properties.
extension _NullableMediaTrackSettings on MediaTrackSettings {
  @JS('facingMode')
  external String? get facingModeNullable;

  @JS('focusDistance')
  external num? get focusDistanceNullable;

  @JS('focusMode')
  external String? get focusModeNullable;

  @JS('torch')
  external bool? get torchNullable;

  @JS('zoom')
  external num? get zoomNullable;
}
