import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';

/// This class represents an exception thrown by the [MobileScannerController].
class MobileScannerException implements Exception {
  const MobileScannerException({
    required this.errorCode,
    this.errorDetails,
  });

  /// The error code of the exception.
  final MobileScannerErrorCode errorCode;

  /// The additional error details that came with the [errorCode].
  final MobileScannerErrorDetails? errorDetails;

  @override
  String toString() {
    if (errorDetails != null && errorDetails?.message != null) {
      return 'MobileScannerException(${errorCode.name}, ${errorDetails?.message})';
    }
    return 'MobileScannerException(${errorCode.name})';
  }
}

/// The raw error details for a [MobileScannerException].
class MobileScannerErrorDetails {
  const MobileScannerErrorDetails({
    this.code,
    this.details,
    this.message,
  });

  /// The error code from the [PlatformException].
  final String? code;

  /// The details from the [PlatformException].
  final Object? details;

  /// The error message from the [PlatformException].
  final String? message;
}

/// This class represents an exception that is thrown
/// when the scanner was (re)started while a permission request was pending.
///
/// This exception type is only used internally,
/// and is not part of the public API.
class PermissionRequestPendingException implements Exception {}

/// This class represents an exception thrown by the [MobileScannerController]
/// when a barcode scanning error occurs when processing an input frame.
class MobileScannerBarcodeException implements Exception {
  /// Creates a new [MobileScannerBarcodeException] with the given error message.
  const MobileScannerBarcodeException(this.message);

  /// The error message of the exception.
  final String? message;

  @override
  String toString() {
    if (message?.isNotEmpty ?? false) {
      return 'MobileScannerBarcodeException($message)';
    }

    return 'MobileScannerBarcodeException(Could not detect a barcode in the input image.)';
  }
}
