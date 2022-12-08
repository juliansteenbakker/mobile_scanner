/// This enum defines the different error codes for the mobile scanner.
enum MobileScannerErrorCode {
  /// The controller was used
  /// while it was not yet initialized using [MobileScannerController.start].
  controllerUninitialized,

  /// A generic error occurred.
  ///
  /// This error code is used for all errors that do not have a specific error code.
  genericError,

  /// The permission to use the camera was denied.
  permissionDenied,
}
