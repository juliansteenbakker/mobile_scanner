import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerWithoutController extends StatefulWidget {
  const BarcodeScannerWithoutController({Key? key}) : super(key: key);

  @override
  _BarcodeScannerWithoutControllerState createState() =>
      _BarcodeScannerWithoutControllerState();
}

class _BarcodeScannerWithoutControllerState
    extends State<BarcodeScannerWithoutController>
    with SingleTickerProviderStateMixin {
  String? barcode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Builder(
        builder: (context) {
          return Stack(
            children: [
              MobileScanner(
                fit: BoxFit.contain,
                // allowDuplicates: false,
                onDetect: (barcode, args) {
                  setState(() {
                    this.barcode = barcode.rawValue;
                  });
                },
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  alignment: Alignment.bottomCenter,
                  height: 100,
                  color: Colors.black.withOpacity(0.4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 120,
                          height: 50,
                          child: FittedBox(
                            child: Text(
                              barcode ?? 'Scan something!',
                              overflow: TextOverflow.fade,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline4!
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
