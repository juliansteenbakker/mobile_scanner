import 'dart:async';
import 'dart:js_interop';
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/web/barcode_reader.dart';
import 'package:mobile_scanner/src/web/media_track_constraints_delegate.dart';
import 'package:mobile_scanner/src/web/media_track_extension.dart';
import 'package:mobile_scanner/src/web/zxing/zxing_barcode_reader.dart';
import 'package:web/web.dart';

/// A web implementation of the MobileScannerPlatform of the MobileScanner
/// plugin.
class MobileScannerWeb extends MobileScannerPlatform {
  /// Constructs a [MobileScannerWeb] instance.
  MobileScannerWeb();

  /// The alternate script url for the barcode library.
  String? _alternateScriptUrl;

  /// The internal barcode reader.
  BarcodeReader? _barcodeReader;

  /// The stream controller for the barcode stream.
  final StreamController<BarcodeCapture> _barcodesController = StreamController.broadcast();

  /// The subscription for the barcode stream.
  StreamSubscription<Object?>? _barcodesSubscription;

  /// The container div element for the camera view.
  late HTMLDivElement _divElement;

  /// The stream controller for the media track settings stream.
  ///
  /// Currently, only the facing mode setting can be supported,
  /// because that is the only property for video tracks that can be observed.
  ///
  /// See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints#instance_properties_of_video_tracks
  final StreamController<MediaTrackSettings> _settingsController = StreamController.broadcast();

  /// The delegate that retrieves the media track settings.
  final MediaTrackConstraintsDelegate _settingsDelegate = const MediaTrackConstraintsDelegate();

  /// The texture ID for the camera view.
  int _textureId = 1;

  /// The video element for the camera view.
  late HTMLVideoElement _videoElement;

  /// Local storage key for the preferred device id.
  static const String _kPreferredDeviceIdKey = 'mobile_scanner_preferred_device_id';

  /// Get the view type for the platform view factory.
  String _getViewType(int textureId) => 'mobile-scanner-view-$textureId';

  /// Registers this class as the default instance of [MobileScannerPlatform].
  static void registerWith(Registrar registrar) {
    MobileScannerPlatform.instance = MobileScannerWeb();
  }

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodesController.stream;

  @override
  Stream<TorchState> get torchStateStream => _settingsController.stream.map((_) => TorchState.unavailable);

  @override
  Stream<double> get zoomScaleStateStream => _settingsController.stream.map((_) => 1.0);

  /// Create the [HTMLVideoElement] along with its parent container
  /// [HTMLDivElement].
  HTMLVideoElement _createVideoElement(int textureId) {
    final HTMLVideoElement videoElement = HTMLVideoElement();

    videoElement.style
      ..height = '100%'
      ..width = '100%'
      ..objectFit = 'cover'
      ..transformOrigin = 'center'
      ..pointerEvents = 'none';

    // Do not show the media controls, as this is a preview element.
    // Also prevent play/pause events from changing the media controls.
    videoElement
      ..controls = false
      ..onplay =
          (JSAny _) {
            videoElement.controls = false;
          }.toJS
      ..onpause =
          (JSAny _) {
            videoElement.controls = false;
          }.toJS;

    // Attach the video element to its parent container
    // and setup the PlatformView factory for this `textureId`.
    _divElement =
        HTMLDivElement()
          ..style.objectFit = 'cover'
          ..style.height = '100%'
          ..style.width = '100%'
          ..append(videoElement);

    ui_web.platformViewRegistry.registerViewFactory(_getViewType(textureId), (_) => _divElement);

    return videoElement;
  }

  void _handleMediaTrackSettingsChange(MediaTrackSettings settings) {
    if (_settingsController.isClosed) {
      return;
    }

    _settingsController.add(settings);
  }

  /// Flip the [videoElement] horizontally,
  /// if the [videoStream] indicates that is facing the user.
  void _maybeFlipVideoPreview(HTMLVideoElement videoElement, MediaStream videoStream) {
    final MediaTrackSettings? settings = _settingsDelegate.getSettings(videoStream);

    // First try checking the facing mode.
    if (settings?.facingModeNullable?.toDart == 'user') {
      videoElement.style.transform = 'scaleX(-1)';

      return;
    }

    final MediaStreamTrack videoTrack = videoStream.getVideoTracks().toDart.first;

    // On MacOS, even though the facing mode is supported, it is not reported.
    // Use the label for FaceTime cameras to detect the user facing webcam.
    if (videoTrack.label.contains('FaceTime')) {
      videoElement.style.transform = 'scaleX(-1)';
    }
  }

  /// Log all available video input devices to the console.
  ///
  /// Note: Without prior camera permission, device labels may be empty in
  /// some browsers for privacy reasons.
  Future<void> _logAvailableVideoInputs() async {
    try {
      // Logging removed after verification
    } on Exception catch (_) {
      // Logging removed after verification
    }
  }

  // Removed unused JSON helper to keep the code minimal.

  // Removed unused heavy probe to avoid double prompts and lint warning.

  String? _getStoredPreferredDeviceId() {
    try {
      return window.localStorage.getItem(_kPreferredDeviceIdKey);
    } on Exception catch (_) {
      return null;
    }
  }

  void _storePreferredDeviceId(String deviceId) {
    try {
      window.localStorage.setItem(_kPreferredDeviceIdKey, deviceId);
    } on Exception catch (_) {
      // Ignore storage errors (e.g., Safari private mode)
    }
  }

  double _readRangeMin(JSObject obj, String key, [double defaultValue = double.infinity]) {
    try {
      if (!js_util.hasProperty(obj, key)) return defaultValue;
      final Object? range = js_util.dartify(js_util.getProperty(obj, key));
      if (range is Map) {
        final Object? minVal = range['min'];
        if (minVal is num) {
          return minVal.toDouble();
        }
      }
    } on Exception catch (_) {}
    return defaultValue;
  }

  List<String> _readCapabilityEnumList(JSObject obj, String key) {
    try {
      if (!js_util.hasProperty(obj, key)) return const <String>[];
      final Object? raw = js_util.dartify(js_util.getProperty(obj, key));
      if (raw is List) {
        return raw.map<String>((e) => e.toString()).toList(growable: false);
      }
    } on Exception catch (_) {}
    return const <String>[];
  }

  Future<double> _scoreDeviceForClose1DScanning(MediaDeviceInfo device) async {
    try {
      final MediaStreamConstraints probeConstraints = MediaStreamConstraints(video: MediaTrackConstraintSet(deviceId: device.deviceId.toJS));

      final MediaStream probeStream = await window.navigator.mediaDevices.getUserMedia(probeConstraints).toDart;
      final MediaStreamTrack track = probeStream.getVideoTracks().toDart.first;

      final MediaTrackSettings settings = track.getSettings();
      final MediaTrackCapabilities capabilities = track.getCapabilities();

      double score = 0;

      // Prefer back-facing
      final String facing = settings.facingModeNullable?.toDart ?? '';
      if (facing == 'environment') score += 100.0;
      if (facing == 'user') score -= 20.0;

      // Prefer autofocus continuous > single-shot > manual
      final List<String> focusModes = _readCapabilityEnumList(capabilities, 'focusMode');
      if (focusModes.contains('continuous')) {
        score += 40.0;
      } else if (focusModes.contains('single-shot')) {
        score += 25.0;
      } else if (focusModes.contains('manual')) {
        score += 10.0;
      }

      // Prefer shorter minimum focus distance (closer focus)
      final double minFocusDistance = _readRangeMin(capabilities, 'focusDistance');
      if (minFocusDistance.isFinite) {
        // Smaller is better. Normalize and invert.
        score += 100.0 / (1.0 + minFocusDistance);
      }

      // Slightly prefer higher max resolution
      final double maxWidth = _readRangeMin(capabilities, 'width', double.nan);
      final double maxHeight = _readRangeMin(capabilities, 'height', double.nan);
      if (!maxWidth.isNaN && !maxHeight.isNaN) {
        score += (maxWidth * maxHeight) / 1e6; // megapixels weight
      }

      // Release resources
      for (final MediaStreamTrack t in probeStream.getTracks().toDart) {
        t.stop();
      }

      return score;
    } on Exception catch (_) {
      return -1.0; // Unusable
    }
  }

  Future<String?> _chooseBestVideoInputDeviceId(CameraFacing preferredFacing) async {
    final JSArray<MediaDeviceInfo> jsDevices = await window.navigator.mediaDevices.enumerateDevices().toDart;
    final List<MediaDeviceInfo> devices = jsDevices.toDart;

    final List<MediaDeviceInfo> videoInputs = <MediaDeviceInfo>[
      for (final MediaDeviceInfo d in devices)
        if (d.kind == 'videoinput') d,
    ];

    if (videoInputs.isEmpty) return null;

    // Try to score all devices. Score back-facing higher via settings later.
    double bestScore = double.negativeInfinity;
    String? bestId;

    for (final MediaDeviceInfo d in videoInputs) {
      final double score = await _scoreDeviceForClose1DScanning(d);
      if (score > bestScore) {
        bestScore = score;
        bestId = d.deviceId;
      }
    }

    return bestId;
  }

  Future<void> _applyCloseFocusConstraints(MediaStreamTrack track) async {
    try {
      final MediaTrackCapabilities capabilities = track.getCapabilities();
      final JSObject caps = capabilities as JSObject;

      final List<String> focusModes = _readCapabilityEnumList(caps, 'focusMode');
      final bool hasContinuous = focusModes.contains('continuous');
      final bool hasSingleShot = focusModes.contains('single-shot');
      final bool hasManual = focusModes.contains('manual');

      final Map<String, Object> constraints = <String, Object>{};

      if (hasContinuous) {
        constraints['focusMode'] = 'continuous';
      } else if (hasSingleShot) {
        constraints['focusMode'] = 'single-shot';
      } else if (hasManual) {
        final double minFocusDistance = _readRangeMin(caps, 'focusDistance', double.nan);
        if (!minFocusDistance.isNaN) {
          constraints['focusMode'] = 'manual';
          constraints['focusDistance'] = minFocusDistance;
        }
      }

      // Prefer continuous exposure/white balance if available
      final List<String> exposureModes = _readCapabilityEnumList(caps, 'exposureMode');
      if (exposureModes.contains('continuous')) constraints['exposureMode'] = 'continuous';
      final List<String> wbModes = _readCapabilityEnumList(caps, 'whiteBalanceMode');
      if (wbModes.contains('continuous')) constraints['whiteBalanceMode'] = 'continuous';

      if (constraints.isEmpty) return;

      final Object jsConstraints = js_util.jsify(constraints) as Object;
      await js_util.promiseToFuture<void>(js_util.callMethod(track, 'applyConstraints', <Object>[jsConstraints]));
    } on Exception catch (_) {
      // Silently ignore if not supported
    }
  }

  /// Prepare a [MediaStream] for the video output.
  ///
  /// This method requests permission to use the camera.
  ///
  /// Throws a [MobileScannerException] if the permission was denied,
  /// or if using a video stream, with the given set of constraints, is
  /// unsupported.
  Future<MediaStream> _prepareVideoStream(CameraFacing cameraDirection) async {
    if (window.navigator.mediaDevices.isUndefinedOrNull) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.unsupported,
        errorDetails: MobileScannerErrorDetails(message: 'This browser does not support displaying video from the camera.'),
      );
    }

    // List available video input devices before requesting camera access.
    await _logAvailableVideoInputs();

    final MediaTrackSupportedConstraints capabilities = window.navigator.mediaDevices.getSupportedConstraints();

    final MediaStreamConstraints constraints;
    String? chosenDeviceId = _getStoredPreferredDeviceId();
    bool chosenIdIsValid = false;
    try {
      if (chosenDeviceId != null) {
        final List<MediaDeviceInfo> devices = (await window.navigator.mediaDevices.enumerateDevices().toDart).toDart;
        chosenIdIsValid = devices.any((d) => d.kind == 'videoinput' && d.deviceId == chosenDeviceId);
        if (!chosenIdIsValid) {
          chosenDeviceId = null;
        }
      }
    } on Exception catch (_) {}

    chosenDeviceId ??= await _chooseBestVideoInputDeviceId(cameraDirection);

    if (chosenDeviceId != null) {
      constraints = MediaStreamConstraints(video: MediaTrackConstraintSet(deviceId: chosenDeviceId.toJS));
    } else if (capabilities.isUndefinedOrNull || !capabilities.facingMode) {
      constraints = MediaStreamConstraints(video: true.toJS);
    } else {
      final String facingMode = _settingsDelegate.getFacingMode(cameraDirection);
      constraints = MediaStreamConstraints(video: MediaTrackConstraintSet(facingMode: facingMode.toJS));
    }

    try {
      // Retrieving the media devices requests the camera permission.
      final MediaStream videoStream = await window.navigator.mediaDevices.getUserMedia(constraints).toDart;

      // Apply close-focus friendly constraints when supported
      try {
        final MediaStreamTrack videoTrack = videoStream.getVideoTracks().toDart.first;
        await _applyCloseFocusConstraints(videoTrack);
      } on Exception catch (_) {}

      // Persist chosen deviceId on first success
      if (chosenDeviceId != null && !chosenIdIsValid) {
        _storePreferredDeviceId(chosenDeviceId);
      }

      return videoStream;
    } on DOMException catch (error, stackTrace) {
      // If a specific deviceId failed, try falling back to facingMode/default once.
      if (chosenDeviceId != null) {
        try {
          final MediaStreamConstraints fallbackConstraints;
          if (capabilities.isUndefinedOrNull || !capabilities.facingMode) {
            fallbackConstraints = MediaStreamConstraints(video: true.toJS);
          } else {
            final String facingMode = _settingsDelegate.getFacingMode(cameraDirection);
            fallbackConstraints = MediaStreamConstraints(video: MediaTrackConstraintSet(facingMode: facingMode.toJS));
          }

          final MediaStream fallbackStream = await window.navigator.mediaDevices.getUserMedia(fallbackConstraints).toDart;

          try {
            final MediaStreamTrack videoTrack = fallbackStream.getVideoTracks().toDart.first;
            await _applyCloseFocusConstraints(videoTrack);
          } on Exception catch (_) {}

          return fallbackStream;
        } on Exception catch (_) {
          // continue to error handling below
        }
      }

      final String errorMessage = error.toString();

      MobileScannerErrorCode errorCode = MobileScannerErrorCode.genericError;

      // Handle both unsupported and permission errors from the web.
      if (errorMessage.contains('NotFoundError') || errorMessage.contains('NotSupportedError')) {
        errorCode = MobileScannerErrorCode.unsupported;
      } else if (errorMessage.contains('NotAllowedError')) {
        errorCode = MobileScannerErrorCode.permissionDenied;
      }

      throw MobileScannerException(
        errorCode: errorCode,
        errorDetails: MobileScannerErrorDetails(message: errorMessage, details: stackTrace.toString()),
      );
    }
  }

  @override
  Future<BarcodeCapture?> analyzeImage(String path, {List<BarcodeFormat> formats = const <BarcodeFormat>[]}) {
    throw UnsupportedError('analyzeImage() is not supported on the web.');
  }

  @override
  Widget buildCameraView() {
    if (_barcodeReader?.isScanning ?? false) {
      return HtmlElementView(viewType: _getViewType(_textureId));
    }

    return const SizedBox();
  }

  @override
  Future<void> resetZoomScale() {
    throw UnsupportedError(
      'Setting the zoom scale is not supported for video tracks on the web.\n'
      'See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints#instance_properties_of_video_tracks',
    );
  }

  @override
  void setBarcodeLibraryScriptUrl(String scriptUrl) {
    _alternateScriptUrl ??= scriptUrl;
  }

  @override
  Future<void> setZoomScale(double zoomScale) {
    throw UnsupportedError(
      'Setting the zoom scale is not supported for video tracks on the web.\n'
      'See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints#instance_properties_of_video_tracks',
    );
  }

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    if (_barcodeReader != null) {
      if (_barcodeReader!.paused ?? false) {
        await _barcodeReader?.resume();

        final CameraFacing cameraDirection = _settingsDelegate.getCameraDirection(_barcodeReader?.videoStream);

        return MobileScannerViewAttributes(
          cameraDirection: cameraDirection,
          // The torch of a media stream is not available for video tracks.
          // See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints#instance_properties_of_video_tracks
          currentTorchMode: TorchState.unavailable,
          size: _barcodeReader?.videoSize ?? Size.zero,
        );
      }

      throw MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerAlreadyInitialized,
        errorDetails: MobileScannerErrorDetails(message: MobileScannerErrorCode.controllerAlreadyInitialized.message),
      );
    }

    // If the previous state is a pause, reset scanner.
    if (_barcodesSubscription != null && _barcodesSubscription!.isPaused) {
      await stop();
    }

    _barcodeReader = ZXingBarcodeReader();

    await _barcodeReader?.maybeLoadLibrary(alternateScriptUrl: _alternateScriptUrl);

    // Request camera permissions and prepare the video stream.
    final MediaStream videoStream = await _prepareVideoStream(startOptions.cameraDirection);

    try {
      // Clear the existing barcodes.
      if (!_barcodesController.isClosed) {
        _barcodesController.add(const BarcodeCapture());
      }

      // Listen for changes to the media track settings.
      _barcodeReader?.setMediaTrackSettingsListener(_handleMediaTrackSettingsChange);

      _textureId += 1; // Request a new texture.

      _videoElement = _createVideoElement(_textureId);

      _maybeFlipVideoPreview(_videoElement, videoStream);

      await _barcodeReader?.start(startOptions, videoElement: _videoElement, videoStream: videoStream);
    } catch (error, stackTrace) {
      throw MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
        errorDetails: MobileScannerErrorDetails(message: error.toString(), details: stackTrace.toString()),
      );
    }

    try {
      _barcodesSubscription = _barcodeReader?.detectBarcodes().listen(
        (BarcodeCapture barcode) {
          if (_barcodesController.isClosed) {
            return;
          }

          _barcodesController.add(barcode);
        },
        onError: (Object error) {
          if (_barcodesController.isClosed) {
            return;
          }

          _barcodesController.addError(error);
        },
        // Errors are handled gracefully by forwarding them.
        cancelOnError: false,
      );

      final bool hasTorch = await _barcodeReader?.hasTorch() ?? false;

      if (hasTorch && startOptions.torchEnabled) {
        await _barcodeReader?.setTorchState(TorchState.on);
      }

      final CameraFacing cameraDirection = _settingsDelegate.getCameraDirection(videoStream);

      return MobileScannerViewAttributes(
        cameraDirection: cameraDirection,
        // The torch of a media stream is not available for video tracks.
        // See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints#instance_properties_of_video_tracks
        currentTorchMode: TorchState.unavailable,
        size: _barcodeReader?.videoSize ?? Size.zero,
      );
    } catch (error, stackTrace) {
      throw MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
        errorDetails: MobileScannerErrorDetails(message: error.toString(), details: stackTrace.toString()),
      );
    }
  }

  @override
  Future<void> pause() async {
    _barcodesSubscription?.pause();
    _barcodeReader?.pause();
  }

  @override
  Future<void> stop() async {
    // Ensure the barcode scanner is stopped, by cancelling the subscription.
    await _barcodesSubscription?.cancel();
    _barcodesSubscription = null;

    await _barcodeReader?.stop();
    _barcodeReader = null;
  }

  @override
  Future<void> toggleTorch() {
    throw UnsupportedError(
      'Setting the torch state is not supported for video tracks on the web.\n'
      'See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints#instance_properties_of_video_tracks',
    );
  }

  @override
  Future<void> updateScanWindow(Rect? window) {
    // A scan window is not supported on the web,
    // because the scanner does not expose size information for the barcodes.
    return Future<void>.value();
  }

  @override
  Future<void> dispose() async {
    // The `_barcodesController` and `_settingsController`
    // are not closed, as these have the same lifetime as the plugin.
    await stop();
  }
}
