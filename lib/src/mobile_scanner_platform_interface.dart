import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The platform interface for the `mobile_scanner` plugin.
abstract class MobileScannerPlatform extends PlatformInterface {
  /// Constructs a MobileScannerPlatform.
  MobileScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static MobileScannerPlatform _instance = MethodChannelMobileScanner();

  /// The default instance of [MobileScannerPlatform] to use.
  ///
  /// Defaults to [MethodChannelMobileScanner].
  static MobileScannerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MobileScannerPlatform] when
  /// they register themselves.
  static set instance(MobileScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Get the stream of barcode captures.
  Stream<BarcodeCapture?> get barcodesStream {
    throw UnimplementedError('barcodesStream has not been implemented.');
  }

  /// Get the stream of torch state changes.
  Stream<TorchState> get torchStateStream {
    throw UnimplementedError('torchStateStream has not been implemented.');
  }

  /// Get the stream of zoom scale changes.
  Stream<double> get zoomScaleStateStream {
    throw UnimplementedError('zoomScaleStateStream has not been implemented.');
  }

  /// Analyze a local image file for barcodes.
  ///
  /// The [path] is the path to the file on disk.
  ///
  /// Returns the barcodes that were found in the image.
  Future<BarcodeCapture?> analyzeImage(String path) {
    throw UnimplementedError('analyzeImage() has not been implemented.');
  }

  /// Build the camera view for the barcode scanner.
  Widget buildCameraView() {
    throw UnimplementedError('buildCameraView() has not been implemented.');
  }

  /// Reset the zoom scale, so that the camera is fully zoomed out.
  Future<void> resetZoomScale() {
    throw UnimplementedError('resetZoomScale() has not been implemented.');
  }

  /// Set the source url for the barcode library.
  ///
  /// This is only supported on the web.
  void setBarcodeLibraryScriptUrl(String scriptUrl) {}

  /// Set the zoom scale of the camera.
  ///
  /// The [zoomScale] must be between `0.0` and `1.0` (both inclusive).
  /// A value of `0.0` indicates that the camera is fully zoomed out,
  /// while `1.0` indicates that the camera is fully zoomed in.
  Future<void> setZoomScale(double zoomScale) {
    throw UnimplementedError('setZoomScale() has not been implemented.');
  }

  /// Start the barcode scanner and prepare a scanner view.
  ///
  /// Upon calling this method, the necessary camera permission will be requested.
  ///
  /// The given [StartOptions.cameraDirection] is used as the direction for the camera that needs to be set up.
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) {
    throw UnimplementedError('start() has not been implemented.');
  }

  /// Stop the camera.
  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// Toggle the torch on the active camera on or off.
  Future<void> toggleTorch() {
    throw UnimplementedError('toggleTorch() has not been implemented.');
  }

  /// Update the scan window to the given [window] rectangle.
  ///
  /// Any barcodes that do not intersect with the given [window] will be ignored.
  ///
  /// If [window] is `null`, the scan window will be reset to the full screen.
  Future<void> updateScanWindow(Rect? window) {
    throw UnimplementedError('updateScanWindow() has not been implemented.');
  }

  /// Set inverting image colors (for negative Data Matrixes) on intervals.
  Future<void> setIntervalInvertImage(bool intervalInvertImage) {
    throw UnimplementedError('setIntervalInvertImage() has not been implemented.');
  }

  /// Dispose of this [MobileScannerPlatform] instance.
  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
