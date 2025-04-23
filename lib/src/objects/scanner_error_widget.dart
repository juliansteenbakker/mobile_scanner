/// @docImport 'package:mobile_scanner/src/mobile_scanner.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';

/// This widget represents the default error widget for the [MobileScanner]
/// widget.
class ScannerErrorWidget extends StatelessWidget {
  /// Creates a new [ScannerErrorWidget] for the given [error].
  const ScannerErrorWidget({required this.error, super.key});

  /// The error that occurred.
  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Icon(Icons.error, color: Colors.white),
            ),
            if (kDebugMode) ...[
              Text(
                error.errorCode.message,
                style: const TextStyle(color: Colors.white),
              ),
              if (error.errorDetails?.message case final String message)
                Text(message, style: const TextStyle(color: Colors.white)),
            ] else
              Text(
                MobileScannerErrorCode.genericError.message,
                style: const TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
