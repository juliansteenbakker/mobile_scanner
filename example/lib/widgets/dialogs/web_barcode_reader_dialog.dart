import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Dialog for selecting the web barcode reader backend.
///
/// Only intended to be shown on the web platform.
class WebBarcodeReaderDialog extends StatelessWidget {
  /// Creates a [WebBarcodeReaderDialog].
  const WebBarcodeReaderDialog({
    required this.selectedReader,
    super.key,
  });

  /// The currently selected reader.
  final WebBarcodeReader selectedReader;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Web barcode reader'),
      children: [
        for (final reader in WebBarcodeReader.values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(reader),
            child: ListTile(
              leading: Icon(
                reader == selectedReader
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(_label(reader)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  String _label(WebBarcodeReader reader) => switch (reader) {
    WebBarcodeReader.auto =>
      'Auto (native BarcodeDetector → zxing-wasm fallback)',
    WebBarcodeReader.barcodeDetector =>
      'BarcodeDetector (native – Chrome/Edge/Safari 17+)',
    WebBarcodeReader.zxingWasm => 'zxing-wasm (WASM – all browsers)',
    WebBarcodeReader.zxingJs => 'ZXing-js (legacy – for comparison)',
  };
}
