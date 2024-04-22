import 'dart:js_interop';

import 'package:web/web.dart';

/// This class represents a delegate that manages the constraints for a [MediaStreamTrack].
final class MediaTrackConstraintsDelegate {
  /// Constructs a [MediaTrackConstraintsDelegate] instance.
  const MediaTrackConstraintsDelegate();

  /// Get the settings for the given [mediaStream].
  MediaTrackSettings? getSettings(MediaStream? mediaStream) {
    final List<MediaStreamTrack>? tracks = mediaStream?.getVideoTracks().toDart;

    if (tracks == null || tracks.isEmpty) {
      return null;
    }

    final MediaStreamTrack track = tracks.first;

    final MediaTrackCapabilities capabilities = track.getCapabilities();
    final MediaTrackSettings settings = track.getSettings();

    if (capabilities.facingMode.toDart.isEmpty) {
      return MediaTrackSettings(
        width: settings.width,
        height: settings.height,
      );
    }

    return MediaTrackSettings(
      width: settings.width,
      height: settings.height,
      facingMode: settings.facingMode,
    );
  }
}
