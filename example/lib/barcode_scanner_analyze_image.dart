import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerAnalyzeImage extends StatefulWidget {
  const BarcodeScannerAnalyzeImage({super.key});

  @override
  State<BarcodeScannerAnalyzeImage> createState() =>
      _BarcodeScannerAnalyzeImageState();
}

class _BarcodeScannerAnalyzeImageState
    extends State<BarcodeScannerAnalyzeImage> {
  final MobileScannerController _controller = MobileScannerController();

  BarcodeCapture? _barcodeCapture;

  Future<void> _analyzeImageFromFile() async {
    try {
      final XFile? file =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (!mounted || file == null) {
        return;
      }

      final BarcodeCapture? barcodeCapture =
          await _controller.analyzeImage(file.path);

      if (mounted) {
        setState(() {
          _barcodeCapture = barcodeCapture;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    Widget label = const Text('Pick a file to detect barcode');

    if (_barcodeCapture != null) {
      label = Text(
        _barcodeCapture?.barcodes.firstOrNull?.displayValue ??
            'No barcode detected',
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analyze image from file')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ElevatedButton(
                onPressed: kIsWeb ? null : _analyzeImageFromFile,
                child: kIsWeb
                    ? const Text('Analyze image is not supported on web')
                    : const Text('Choose file'),
              ),
            ),
          ),
          Expanded(child: Center(child: label)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
