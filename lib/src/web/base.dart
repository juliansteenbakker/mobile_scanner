import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/web/media.dart';

class JsLibrary {
  /// The name of global variable where library is stored.
  /// Used to properly import the library if [usesRequireJs] flag is true
  final String contextName;
  final String url;

  /// If js code checks for 'define' variable.
  /// E.g. if at the beginning you see code like
  /// if (typeof define === "function" && define.amd)
  final bool usesRequireJs;

  const JsLibrary({
    required this.contextName,
    required this.url,
    required this.usesRequireJs,
  });
}

abstract class WebBarcodeReaderBase {
  /// Timer used to capture frames to be analyzed
  Duration frameInterval = const Duration(milliseconds: 200);
  final html.DivElement videoContainer;

  WebBarcodeReaderBase({
    required this.videoContainer,
  });

  bool get isStarted;

  int get videoWidth;
  int get videoHeight;

  /// JS libraries to be injected into html page.
  List<JsLibrary> get jsLibraries;

  /// Starts streaming video
  Future<void> start({
    required CameraFacing cameraFacing,
    List<BarcodeFormat>? formats,
    Duration? detectionTimeout,
  });

  /// Starts scanning QR codes or barcodes
  Stream<Barcode?> detectBarcodeContinuously();

  /// Stops streaming video
  Future<void> stop();

  /// Can enable or disable the flash if available
  Future<void> toggleTorch({required bool enabled});

  /// Determine whether device has flash
  Future<bool> hasTorch();
}

mixin InternalStreamCreation on WebBarcodeReaderBase {
  /// The video stream.
  /// Will be initialized later to see which camera needs to be used.
  html.MediaStream? localMediaStream;
  final html.VideoElement video = html.VideoElement();

  @override
  int get videoWidth => video.videoWidth;
  @override
  int get videoHeight => video.videoHeight;

  Future<html.MediaStream?> initMediaStream(CameraFacing cameraFacing) async {
    // Check if browser supports multiple camera's and set if supported
    final Map? capabilities =
        html.window.navigator.mediaDevices?.getSupportedConstraints();
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
        await html.window.navigator.mediaDevices?.getUserMedia(constraints);
    return stream;
  }

  void prepareVideoElement(html.VideoElement videoSource);

  Future<void> attachStreamToVideo(
    html.MediaStream stream,
    html.VideoElement videoSource,
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
  Future<List<String>> getSupportedTorchStates() async {
    try {
      final track = localMediaStream?.getVideoTracks();
      if (track != null) {
        final imageCapture = ImageCapture(track.first);
        final photoCapabilities = await promiseToFuture<PhotoCapabilities>(
          imageCapture.getPhotoCapabilities(),
        );
        final fillLightMode = photoCapabilities.fillLightMode;
        if (fillLightMode != null) {
          return fillLightMode;
        }
      }
    } catch (e) {
      // ImageCapture is not supported by some browsers:
      // https://developer.mozilla.org/en-US/docs/Web/API/ImageCapture#browser_compatibility
    }
    return [];
  }

  @override
  Future<bool> hasTorch() async {
    return (await getSupportedTorchStates()).isNotEmpty;
  }

  @override
  Future<void> toggleTorch({required bool enabled}) async {
    final hasTorch = await this.hasTorch();
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

@JS('Promise')
@staticInterop
class Promise<T> {}

@JS()
@anonymous
class PhotoCapabilities {
  /// Returns an array of available fill light options. Options include auto, off, or flash.
  external List<String>? get fillLightMode;
}

@JS('ImageCapture')
@staticInterop
class ImageCapture {
  /// MediaStreamTrack
  external factory ImageCapture(dynamic track);
}

extension ImageCaptureExt on ImageCapture {
  external Promise<PhotoCapabilities> getPhotoCapabilities();
}

@JS('Map')
@staticInterop
class JsMap {
  external factory JsMap();
}

extension JsMapExt on JsMap {
  external void set(dynamic key, dynamic value);
  external dynamic get(dynamic key);
}
