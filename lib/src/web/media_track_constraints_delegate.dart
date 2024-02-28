import 'dart:js_interop';

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
      facingMode: settings.facingMode,
      aspectRatio: settings.aspectRatio,
    );
  }
}
