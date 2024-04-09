import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/web/barcode_reader.dart';
import 'package:mobile_scanner/src/web/zxing/zxing_barcode_reader.dart';
import 'package:web/web.dart';

/// A web implementation of the MobileScannerPlatform of the MobileScanner plugin.
class MobileScannerWeb extends MobileScannerPlatform {
  /// Constructs a [MobileScannerWeb] instance.
  MobileScannerWeb();

  /// The alternate script url for the barcode library.
  String? _alternateScriptUrl;

  /// The internal barcode reader.
  final BarcodeReader _barcodeReader = ZXingBarcodeReader();

  /// The stream controller for the barcode stream.
  final StreamController<BarcodeCapture> _barcodesController =
      StreamController.broadcast();

  /// The subscription for the barcode stream.
  StreamSubscription<Object?>? _barcodesSubscription;

  /// The container div element for the camera view.
  ///
  /// This container element is used by the barcode reader.
  HTMLDivElement? _divElement;

  /// The flag that keeps track of whether a permission request is in progress.
  ///
  /// On the web, a permission request triggers a dialog, that in turn triggers a lifecycle change.
  /// While the permission request is in progress, any attempts at (re)starting the camera should be ignored.
  bool _permissionRequestInProgress = false;

  /// The stream controller for the media track settings stream.
  ///
  /// Currently, only the facing mode setting can be supported,
  /// because that is the only property for video tracks that can be observed.
  ///
  /// See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints#instance_properties_of_video_tracks
  final StreamController<MediaTrackSettings> _settingsController =
      StreamController.broadcast();

  /// The view type for the platform view factory.
  static const String _viewType = 'MobileScannerWeb';

  static void registerWith(Registrar registrar) {
    MobileScannerPlatform.instance = MobileScannerWeb();
  }

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodesController.stream;

  @override
  Stream<TorchState> get torchStateStream =>
      _settingsController.stream.map((_) => TorchState.unavailable);

  @override
  Stream<double> get zoomScaleStateStream =>
      _settingsController.stream.map((_) => 1.0);

  void _handleMediaTrackSettingsChange(MediaTrackSettings settings) {
    if (_settingsController.isClosed) {
      return;
    }

    _settingsController.add(settings);
  }

  /// Prepare a [MediaStream] for the video output.
  ///
  /// This method requests permission to use the camera.
  ///
  /// Throws a [MobileScannerException] if the permission was denied,
  /// or if using a video stream, with the given set of constraints, is unsupported.
  Future<MediaStream> _prepareVideoStream(
    CameraFacing cameraDirection,
  ) async {
    if (window.navigator.mediaDevices.isUndefinedOrNull) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.unsupported,
        errorDetails: MobileScannerErrorDetails(
          message:
              'This browser does not support displaying video from the camera.',
        ),
      );
    }

    final MediaTrackSupportedConstraints capabilities =
        window.navigator.mediaDevices.getSupportedConstraints();

    final MediaStreamConstraints constraints;

    if (capabilities.isUndefinedOrNull || !capabilities.facingMode) {
      constraints = MediaStreamConstraints(video: true.toJS);
    } else {
      final String facingMode = switch (cameraDirection) {
        CameraFacing.back => 'environment',
        CameraFacing.front => 'user',
      };

      constraints = MediaStreamConstraints(
        video: MediaTrackConstraintSet(
          facingMode: facingMode.toJS,
        ),
      );
    }

    try {
      // Retrieving the media devices requests the camera permission.
      _permissionRequestInProgress = true;

      final MediaStream videoStream =
          await window.navigator.mediaDevices.getUserMedia(constraints).toDart;

      // At this point the permission is granted.
      _permissionRequestInProgress = false;

      return videoStream;
    } on DOMException catch (error, stackTrace) {
      final String errorMessage = error.toString();

      MobileScannerErrorCode errorCode = MobileScannerErrorCode.genericError;

      // Handle both unsupported and permission errors from the web.
      if (errorMessage.contains('NotFoundError') ||
          errorMessage.contains('NotSupportedError')) {
        errorCode = MobileScannerErrorCode.unsupported;
      } else if (errorMessage.contains('NotAllowedError')) {
        errorCode = MobileScannerErrorCode.permissionDenied;
      }

      // At this point the permission request completed, although with an error,
      // but the error is irrelevant.
      _permissionRequestInProgress = false;

      throw MobileScannerException(
        errorCode: errorCode,
        errorDetails: MobileScannerErrorDetails(
          message: errorMessage,
          details: stackTrace.toString(),
        ),
      );
    }
  }

  @override
  Future<BarcodeCapture?> analyzeImage(String path) {
    throw UnsupportedError('analyzeImage() is not supported on the web.');
  }

  @override
  Widget buildCameraView() {
    if (!_barcodeReader.isScanning) {
      return const SizedBox();
    }

    return const HtmlElementView(viewType: _viewType);
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
  Future<void> setTorchState(TorchState torchState) {
    throw UnsupportedError(
      'Setting the torch state is not supported for video tracks on the web.\n'
      'See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints#instance_properties_of_video_tracks',
    );
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
    // If the permission request has not yet completed,
    // the camera view is not ready yet.
    // Prevent the permission popup from triggering a restart of the scanner.
    if (_permissionRequestInProgress) {
      throw PermissionRequestPendingException();
    }

    await _barcodeReader.maybeLoadLibrary(
      alternateScriptUrl: _alternateScriptUrl,
    );

    // Setup the view factory & container element.
    if (_divElement == null) {
      _divElement = (document.createElement('div') as HTMLDivElement)
        ..style.width = '100%'
        ..style.height = '100%';

      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int id) => _divElement!,
      );
    }

    if (_barcodeReader.isScanning) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerAlreadyInitialized,
        errorDetails: MobileScannerErrorDetails(
          message:
              'The scanner was already started. Call stop() before calling start() again.',
        ),
      );
    }

    // Request camera permissions and prepare the video stream.
    final MediaStream videoStream = await _prepareVideoStream(
      startOptions.cameraDirection,
    );

    try {
      // Clear the existing barcodes.
      if (!_barcodesController.isClosed) {
        _barcodesController.add(const BarcodeCapture());
      }

      // Listen for changes to the media track settings.
      _barcodeReader.setMediaTrackSettingsListener(
        _handleMediaTrackSettingsChange,
      );

      final HTMLVideoElement videoElement;

      // Attach the video element to the DOM, through its parent container.
      // If a video element is already present, reuse it.
      if (_divElement!.children.length == 0) {
        videoElement = document.createElement('video') as HTMLVideoElement;

        _divElement!.appendChild(videoElement);
      } else {
        videoElement = _divElement!.children.item(0)! as HTMLVideoElement;
      }

      await _barcodeReader.start(
        startOptions,
        videoElement: videoElement,
        videoStream: videoStream,
      );
    } catch (error, stackTrace) {
      throw MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
        errorDetails: MobileScannerErrorDetails(
          message: error.toString(),
          details: stackTrace.toString(),
        ),
      );
    }

    try {
      _barcodesSubscription = _barcodeReader.detectBarcodes().listen(
        (BarcodeCapture barcode) {
          if (_barcodesController.isClosed) {
            return;
          }

          _barcodesController.add(barcode);
        },
      );

      final bool hasTorch = await _barcodeReader.hasTorch();

      if (hasTorch && startOptions.torchEnabled) {
        await _barcodeReader.setTorchState(TorchState.on);
      }

      return MobileScannerViewAttributes(
        hasTorch: hasTorch,
        size: _barcodeReader.videoSize,
      );
    } catch (error, stackTrace) {
      throw MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
        errorDetails: MobileScannerErrorDetails(
          message: error.toString(),
          details: stackTrace.toString(),
        ),
      );
    }
  }

  @override
  Future<void> stop() async {
    if (_barcodesController.isClosed) {
      return;
    }

    // Ensure the barcode scanner is stopped, by cancelling the subscription.
    await _barcodesSubscription?.cancel();
    _barcodesSubscription = null;

    await _barcodeReader.stop();
  }

  @override
  Future<void> updateScanWindow(Rect? window) {
    // A scan window is not supported on the web,
    // because the scanner does not expose size information for the barcodes.
    return Future<void>.value();
  }

  @override
  Future<void> dispose() async {
    if (_barcodesController.isClosed) {
      return;
    }

    await stop();
    await _barcodesController.close();
    await _settingsController.close();
  }
}
