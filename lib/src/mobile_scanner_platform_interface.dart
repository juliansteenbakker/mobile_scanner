import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
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

  /// Analyze a local image file for barcodes.
  ///
  /// Returns whether the file at the given [path] contains a barcode.
  Future<bool> analyzeImage(String path) {
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
  /// The given [cameraDirection] is used as the direction for the camera that needs to be set up.
  Future<void> start(CameraFacing cameraDirection) {
    throw UnimplementedError('start() has not been implemented.');
  }

  /// Stop the camera.
  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// Switch between the front and back camera.
  Future<void> switchCamera() {
    throw UnimplementedError('switchCamera() has not been implemented.');
  }

  /// Switch the torch on or off.
  ///
  /// Does nothing if the device has no torch.
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

  /// Dispose of this [MobileScannerPlatform] instance.
  void dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
