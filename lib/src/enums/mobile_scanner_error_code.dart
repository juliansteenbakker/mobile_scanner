import 'package:flutter/services.dart';
import 'package:mobile_scanner/src/mobile_scanner.dart' show MobileScanner;
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';

/// This enum defines the different error codes for the mobile scanner.
enum MobileScannerErrorCode {
  /// The controller was already started.
  ///
  /// The controller should be stopped using [MobileScannerController.stop],
  /// before restarting it.
  controllerAlreadyInitialized,

  /// The controller was used after being disposed.
  controllerDisposed,

  /// The controller was used
  /// while it was not yet initialized using [MobileScannerController.start].
  controllerUninitialized,

  /// A generic error occurred.
  ///
  /// This error code is used for all errors that do not have a specific error
  /// code.
  genericError,

  /// The permission to use the camera was denied.
  permissionDenied,

  /// Scanning is unsupported on the current device.
  unsupported,

  /// The controller is currently initializing.
  ///
  /// This error occurs when [MobileScannerController.start] is called while
  /// a previous initialization is still in progress.
  ///
  /// To avoid this error:
  /// - Ensure that [MobileScannerController.start] is awaited before calling it
  ///   again.
  /// - Alternatively, disable automatic initialization by setting
  ///   [MobileScannerController.autoStart] to `false` if you plan to manually
  ///   start the camera.
  controllerInitializing,

  /// The controller is not attached to any widget.
  ///
  /// This error occurs when [MobileScannerController.start] is called
  /// before the controller has been attached to a [MobileScanner] widget.
  ///
  /// To fix this error:
  /// - Ensure that a [MobileScanner] widget is built and linked to the
  ///   controller.
  /// - The [MobileScanner] widget automatically attaches the controller
  ///   when it is initialized.
  /// - Wait until the widget is fully built before calling start.
  controllerNotAttached;

  /// Convert the given [PlatformException.code] to a [MobileScannerErrorCode].
  factory MobileScannerErrorCode.fromPlatformException(
    PlatformException exception,
  ) {
    // The following error code mapping should be kept in sync with their native
    // counterparts. These are located in `MobileScannerErrorCodes.kt` and
    // `MobileScannerErrorCodes.swift`.
    return switch (exception.code) {
      // In case the scanner was already started, report the right error code.
      // If the scanner is already starting, this error code is a signal to the
      // controller to just ignore the attempt.
      'MOBILE_SCANNER_ALREADY_STARTED_ERROR' =>
        MobileScannerErrorCode.controllerAlreadyInitialized,
      // In case no cameras are available, using the scanner is not supported.
      'MOBILE_SCANNER_NO_CAMERA_ERROR' => MobileScannerErrorCode.unsupported,
      'MOBILE_SCANNER_CAMERA_PERMISSION_DENIED' =>
        MobileScannerErrorCode.permissionDenied,
      _ => MobileScannerErrorCode.genericError,
    };
  }

  /// Returns a human-readable error message for the given
  /// [MobileScannerErrorCode].
  String get message {
    switch (this) {
      case MobileScannerErrorCode.controllerUninitialized:
        return 'The MobileScannerController has not been initialized. '
            'Call start() before using it.';
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission denied.';
      case MobileScannerErrorCode.unsupported:
        return 'Scanning is not supported on this device.';
      case MobileScannerErrorCode.controllerAlreadyInitialized:
        return 'The MobileScannerController is already running. '
            'Stop it before starting again.';
      case MobileScannerErrorCode.controllerDisposed:
        return 'The MobileScannerController was used after it was disposed.';
      case MobileScannerErrorCode.controllerInitializing:
        return 'The MobileScannerController is still initializing. '
            'Await the previous call to start() or disable autoStart before '
            'starting manually.';
      case MobileScannerErrorCode.genericError:
        return 'An unexpected error occurred.';
      case MobileScannerErrorCode.controllerNotAttached:
        return 'The MobileScannerController has not been attached to '
            'MobileScanner. Call start() after the MobileScanner widget is '
            'built.';
    }
  }
}
