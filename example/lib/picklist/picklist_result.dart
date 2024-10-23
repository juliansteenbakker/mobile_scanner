import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/picklist/barcode_scanner_picklist.dart';

class PicklistResult extends StatefulWidget {
  const PicklistResult({super.key});

  @override
  State<PicklistResult> createState() => _PicklistResultState();
}

class _PicklistResultState extends State<PicklistResult> {
  String barcode = 'Scan Something!';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Picklist result')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(barcode),
                ElevatedButton(
                  onPressed: () async {
                    final scannedBarcode =
                        await Navigator.of(context).push<Barcode>(
                      MaterialPageRoute(
                        builder: (context) => const BarcodeScannerPicklist(),
                      ),
                    );
                    setState(
                      () {
                        if (scannedBarcode == null) {
                          barcode = 'Scan Something!';
                          return;
                        }
                        if (scannedBarcode.displayValue == null) {
                          barcode = '>>binary<<';
                          return;
                        }
                        barcode = scannedBarcode.displayValue!;
                      },
                    );
                  },
                  child: const Text('Scan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
