import 'dart:js_interop';

import 'package:mobile_scanner/src/web/media_track_extension.dart';
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

    final MediaTrackCapabilities capabilities;

    if (track.getCapabilitiesNullable != null) {
      capabilities = track.getCapabilities();
    } else {
      capabilities = MediaTrackCapabilities();
    }

    final MediaTrackSettings settings = track.getSettings();
    final JSArray<JSString>? facingModes = capabilities.facingModeNullable;

    if (facingModes == null || facingModes.toDart.isEmpty) {
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
