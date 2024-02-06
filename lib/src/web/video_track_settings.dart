import 'dart:js_interop';

import 'package:web/web.dart';

/// This class defines the settings for a video track.
///
/// Since the [MediaTrackSettings] type is the full union of both the base MediaTrackSettings,
/// the tracks settings for audio tracks, and the tracks settings for video tracks,
/// this class only keeps track of the video track settings.
///
/// See also:
///  * https://www.w3.org/TR/mediacapture-streams/#media-track-settings
///  * https://www.w3.org/TR/image-capture/#mediatracksettings-section
class VideoTrackSettings {
  /// Creates a [VideoTrackSettings] instance from a [MediaStreamTrack].
  ///
  /// Since the actual track settings might not have specify all required properties,
  /// query the capabilities before using specific settings.
  ///
  /// Unsupported values fall back to their defaults.
  factory VideoTrackSettings(MediaStreamTrack videoTrack) {
    assert(videoTrack.kind == 'video', 'The given track is not a video track.');

    final MediaTrackSettings settings = videoTrack.getSettings();
    final MediaTrackCapabilities capabilities = videoTrack.getCapabilities();

    final JSAny? facingModeCapability = capabilities.facingMode as JSAny?;
    final JSAny? focusDistanceCapability = capabilities.focusDistance as JSAny?;
    final JSAny? focusModeCapability = capabilities.focusMode as JSAny?;
    final JSAny? torchCapability = capabilities.torch as JSAny?;
    final JSAny? zoomCapability = capabilities.zoom as JSAny?;

    // The width and height are always supported.
    return VideoTrackSettings._(
      width: settings.width,
      height: settings.height,
      facingMode:
          facingModeCapability.isDefinedAndNotNull ? settings.facingMode : '',
      focusDistance: focusDistanceCapability.isDefinedAndNotNull
          ? settings.focusDistance.toDouble()
          : -1.0,
      focusMode:
          focusModeCapability.isDefinedAndNotNull ? settings.focusMode : 'none',
      torch: torchCapability.isDefinedAndNotNull && settings.torch,
      zoom: zoomCapability.isDefinedAndNotNull ? settings.zoom.toDouble() : 1.0,
    );
  }

  /// The private constructor.
  const VideoTrackSettings._({
    required this.facingMode,
    required this.focusDistance,
    required this.focusMode,
    required this.height,
    required this.torch,
    required this.width,
    required this.zoom,
  });

  final String facingMode;
  final double focusDistance;
  final String focusMode;
  final int height;
  final bool torch;
  final int width;
  final double zoom;
}
