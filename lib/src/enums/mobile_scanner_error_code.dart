import 'package:flutter/services.dart';
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
  /// This error code is used for all errors that do not have a specific error code.
  genericError,

  /// The permission to use the camera was denied.
  permissionDenied,

  /// Scanning is unsupported on the current device.
  unsupported;

  /// Convert the given [PlatformException.code] to a [MobileScannerErrorCode].
  factory MobileScannerErrorCode.fromPlatformException(
    PlatformException exception,
  ) {
    // The following error code mapping should be kept in sync with their native counterparts.
    // These are located in `MobileScannerErrorCodes.kt` and `MobileScannerErrorCodes.swift`.
    return switch (exception.code) {
      // In case the scanner was already started, report the right error code.
      // If the scanner is already starting,
      // this error code is a signal to the controller to just ignore the attempt.
      'MOBILE_SCANNER_ALREADY_STARTED_ERROR' =>
        MobileScannerErrorCode.controllerAlreadyInitialized,
      // In case no cameras are available, using the scanner is not supported.
      'MOBILE_SCANNER_NO_CAMERA_ERROR' => MobileScannerErrorCode.unsupported,
      'MOBILE_SCANNER_CAMERA_PERMISSION_DENIED' =>
        MobileScannerErrorCode.permissionDenied,
      _ => MobileScannerErrorCode.genericError,
    };
  }
}
