import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';

/// This class represents an exception throzn by the mobile scanner.
class MobileScannerException implements Exception {
  MobileScannerException({required this.errorCode});

  /// The error code of the exception.
  final MobileScannerErrorCode errorCode;
}
