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
    final MediaTrackSettings settings = track.getSettings();

    String facingMode;
    try {
      // In web 0.5.0 series, there is a mistake in specifying nullable,
      // so it is executed with try-catch as a workaround.
      facingMode = settings.facingMode;
    } catch (e) {
      facingMode = '';
    }

    return MediaTrackSettings(
      width: settings.width,
      height: settings.height,
      facingMode: facingMode,
      aspectRatio: settings.aspectRatio,
    );
  }
}
