import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Widget to display scanned barcodes.
class ScannedBarcodeLabel extends StatelessWidget {
  /// Construct a new [ScannedBarcodeLabel] instance.
  const ScannedBarcodeLabel({required this.barcodes, super.key});

  /// Barcode stream for scanned barcodes to display
  final Stream<BarcodeCapture> barcodes;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: barcodes,
      builder: (context, snapshot) {
        final List<Barcode> scannedBarcodes = snapshot.data?.barcodes ?? [];

        if (scannedBarcodes.isEmpty) {
          return const Text(
            'Scan something!',
            overflow: TextOverflow.fade,
            style: TextStyle(color: Colors.white),
          );
        }

        if (scannedBarcodes.any((e) => e.displayValue != null)) {
          final String displayValues = scannedBarcodes
              .map((e) => e.displayValue)
              .nonNulls
              .join('\n');

          return Text(
            'Display values: $displayValues',
            overflow: TextOverflow.fade,
            style: const TextStyle(color: Colors.white),
          );
        }

        if (scannedBarcodes.any((e) => e.rawValue != null)) {
          final String rawValues = scannedBarcodes
              .map((e) => e.rawValue)
              .nonNulls
              .join('\n');

          return Text(
            'Raw values: $rawValues',
            overflow: TextOverflow.fade,
            style: const TextStyle(color: Colors.white),
          );
        }

        final String rawDecodedBytes = scannedBarcodes
            .map((e) => e.rawDecodedBytes)
            .join('\n');

        return Text(
          'Raw bytes: $rawDecodedBytes',
          overflow: TextOverflow.fade,
          style: const TextStyle(color: Colors.white),
        );
      },
    );
  }
}
