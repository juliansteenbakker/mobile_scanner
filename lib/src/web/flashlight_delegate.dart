import 'dart:js_interop';

import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:web/web.dart';

/// This class represents a flashlight delegate for the web platform.
///
/// It provides an interface to query and update the flashlight state of a [MediaStream].
final class FlashlightDelegate {
  /// Constructs a [FlashlightDelegate] instance.
  const FlashlightDelegate();

  /// Returns a list of supported flashlight modes for the given [mediaStream].
  ///
  /// The [TorchState.off] mode is always supported, regardless of the return value.
  Future<List<TorchState>> getSupportedFlashlightModes(MediaStream? mediaStream) async {
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
  Future<void> setFlashlightState(MediaStream? mediaStream, TorchState value) async {
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
