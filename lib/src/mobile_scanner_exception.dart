import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';

/// This class represents an exception throzn by the mobile scanner.
class MobileScannerException implements Exception {
  const MobileScannerException({
    required this.errorCode,
    this.errorDetails,
  });

  /// The error code of the exception.
  final MobileScannerErrorCode errorCode;

  /// The additional error details that came with the [errorCode].
  final MobileScannerErrorDetails? errorDetails;
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
