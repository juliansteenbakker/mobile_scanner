import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerCustomizable extends StatelessWidget {
  const BarcodeScannerCustomizable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Scanner')),
      body: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: MobileScanner(
            child: (arguments) => ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: kIsWeb
                  ? HtmlElementView(viewType: arguments!.webId!)
                  : Texture(textureId: arguments!.textureId!),
            ),
            allowDuplicates: false,
            onDetect: (barcode, args) {
              final String code = barcode.rawValue!;
              debugPrint('Barcode found! $code');
            },
          ),
        ),
      ),
    );
  }
}
