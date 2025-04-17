import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerErrorWidget extends StatelessWidget {
  const ScannerErrorWidget({super.key, required this.error});

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
                Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
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
