import 'dart:html';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/web/media.dart';

abstract class WebBarcodeReaderBase {
  /// Timer used to capture frames to be analyzed
  final Duration frameInterval;
  final DivElement videoContainer;

  const WebBarcodeReaderBase({
    required this.videoContainer,
    this.frameInterval = const Duration(milliseconds: 200),
  });

  bool get isStarted;

  int get videoWidth;
  int get videoHeight;

  /// Starts streaming video
  Future<void> start({
    required CameraFacing cameraFacing,
  });

  /// Starts scanning QR codes or barcodes
  Stream<String?> detectBarcodeContinuously();

  /// Stops streaming video
  Future<void> stop();

  /// Can enable or disable the flash if available
  Future<void> toggleTorch({required bool enabled});

  /// Determine whether device has flash
  bool get hasTorch;
}

mixin InternalStreamCreation on WebBarcodeReaderBase {
  /// The video stream.
  /// Will be initialized later to see which camera needs to be used.
  MediaStream? localMediaStream;
  final VideoElement video = VideoElement();

  @override
  int get videoWidth => video.videoWidth;
  @override
  int get videoHeight => video.videoHeight;

  Future<MediaStream?> initMediaStream(CameraFacing cameraFacing) async {
    // Check if browser supports multiple camera's and set if supported
    final Map? capabilities =
        window.navigator.mediaDevices?.getSupportedConstraints();
    final Map<String, dynamic> constraints;
    if (capabilities != null && capabilities['facingMode'] as bool) {
      constraints = {
        'video': VideoOptions(
          facingMode:
              cameraFacing == CameraFacing.front ? 'user' : 'environment',
        )
      };
    } else {
      constraints = {'video': true};
    }
    final stream =
        await window.navigator.mediaDevices?.getUserMedia(constraints);
    return stream;
  }

  void prepareVideoElement(VideoElement videoSource);

  Future<void> attachStreamToVideo(
    MediaStream stream,
    VideoElement videoSource,
  );

  @override
  Future<void> stop() async {
    try {
      // Stop the camera stream
      localMediaStream?.getTracks().forEach((track) {
        if (track.readyState == 'live') {
          track.stop();
        }
      });
    } catch (e) {
      debugPrint('Failed to stop stream: $e');
    }
    video.srcObject = null;
    localMediaStream = null;
    videoContainer.children = [];
  }
}

/// Mixin for libraries that don't have built-in torch support
mixin InternalTorchDetection on InternalStreamCreation {
  @override
  bool get hasTorch {
    // TODO: fix flash light. See https://github.com/dart-lang/sdk/issues/48533
    // final track = _localStream?.getVideoTracks();
    // if (track != null) {
    //   final imageCapture = html.ImageCapture(track.first);
    //   final photoCapabilities = await imageCapture.getPhotoCapabilities();
    // }
    return false;
  }

  @override
  Future<void> toggleTorch({required bool enabled}) async {
    if (hasTorch) {
      final track = localMediaStream?.getVideoTracks();
      await track?.first.applyConstraints({
        'advanced': [
          {'torch': enabled}
        ]
      });
    }
  }
}

