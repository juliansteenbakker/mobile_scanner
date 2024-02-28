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

  /// This [Completer] is used to prevent additional calls to the [start] method.
  ///
  /// To handle lifecycle changes properly,
  /// the scanner is stopped when the application is inactive,
  /// and restarted when the application gains focus.
  ///
  /// However, when the camera permission is requested,
  /// the application is put in the inactive state due to the permission popup gaining focus.
  /// Thus, as long as the permission status is not known,
  /// any calls to the [start] method are ignored.
  Completer<void>? _cameraPermissionCompleter;

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

  bool get _hasPendingPermissionRequest {
    return _cameraPermissionCompleter != null &&
        !_cameraPermissionCompleter!.isCompleted;
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
    if ((window.navigator.mediaDevices as JSAny?).isUndefinedOrNull) {
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

    if ((capabilities as JSAny).isUndefinedOrNull || !capabilities.facingMode) {
      constraints = MediaStreamConstraints(video: true.toJS);
    } else {
      final String facingMode = switch (cameraDirection) {
        CameraFacing.back => 'environment',
        CameraFacing.front => 'user',
      };

      constraints = MediaStreamConstraints(
        video: MediaTrackConstraintSet(facingMode: facingMode.toJS) as JSAny,
      );
    }

    try {
      // Retrieving the video track requests the camera permission.
      // If the completer is not null, the permission was never requested before.
      _cameraPermissionCompleter ??= Completer<void>();

      final MediaStream? videoStream = await window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart as MediaStream?;

      // At this point the permission is granted.
      if (!_cameraPermissionCompleter!.isCompleted) {
        _cameraPermissionCompleter!.complete();
      }

      if (videoStream == null) {
        throw const MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
          errorDetails: MobileScannerErrorDetails(
            message:
                'Could not create a video stream from the camera with the given options. '
                'The browser might not support the given constraints.',
          ),
        );
      }

      return videoStream;
    } on DOMException catch (error, stackTrace) {
      // At this point the permission request completed, although with an error,
      // but the error is irrelevant for the completer.
      if (!_cameraPermissionCompleter!.isCompleted) {
        _cameraPermissionCompleter!.complete();
      }

      final String errorMessage = error.toString();

      MobileScannerErrorCode errorCode = MobileScannerErrorCode.genericError;

      // Handle both unsupported and permission errors from the web.
      if (errorMessage.contains('NotFoundError') ||
          errorMessage.contains('NotSupportedError')) {
        errorCode = MobileScannerErrorCode.unsupported;
      } else if (errorMessage.contains('NotAllowedError')) {
        errorCode = MobileScannerErrorCode.permissionDenied;
      }

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
    if (_hasPendingPermissionRequest) {
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

    // Finally, remove the video element from the DOM.
    try {
      final HTMLCollection? divChildren = _divElement?.children;

      // Since the exact element is unknown, remove all children.
      // In practice, there should only be one child, the single video element.
      if (divChildren != null && divChildren.length > 0) {
        for (int i = 0; i < divChildren.length; i++) {
          final Node? child = divChildren.item(i);

          if (child != null) {
            _divElement?.removeChild(child);
          }
        }
      }
    } catch (_) {
      // The video element was no longer a child of the container element.
    }
  }
}
