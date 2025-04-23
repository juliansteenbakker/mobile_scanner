import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Button widget for analyze image function
class ScannerErrorWidget extends StatelessWidget {
  /// Construct a new [ScannerErrorWidget] instance.
  const ScannerErrorWidget({required this.error, super.key});

  /// Error to display
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
            Text(
              error.errorCode.message,
              style: const TextStyle(color: Colors.white),
            ),
            if (error.errorDetails?.message case final String message)
              Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
