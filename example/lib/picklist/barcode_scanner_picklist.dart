import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/picklist/classes/detect_collision.dart';
import 'package:mobile_scanner_example/picklist/widgets/crosshair.dart';
import 'package:mobile_scanner_example/scanner_error_widget.dart';

class BarcodeScannerPicklist extends StatefulWidget {
  const BarcodeScannerPicklist({super.key});

  @override
  State<BarcodeScannerPicklist> createState() => _BarcodeScannerPicklistState();
}

class _BarcodeScannerPicklistState extends State<BarcodeScannerPicklist>
    with WidgetsBindingObserver {
  final _mobileScannerController = MobileScannerController(
    autoStart: false,
  );
  StreamSubscription<Object?>? _barcodesSubscription;

  final _scannerDisabled = ValueNotifier(false);

  bool barcodeDetected = false;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WidgetsBinding.instance.addObserver(this);
    _barcodesSubscription = _mobileScannerController.barcodes.listen(
      _handleBarcodes,
    );
    super.initState();
    unawaited(_mobileScannerController.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_mobileScannerController.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _barcodesSubscription =
            _mobileScannerController.barcodes.listen(_handleBarcodes);

        unawaited(_mobileScannerController.start());
      case AppLifecycleState.inactive:
        unawaited(_barcodesSubscription?.cancel());
        _barcodesSubscription = null;
        unawaited(_mobileScannerController.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_barcodesSubscription?.cancel());
    _barcodesSubscription = null;
    super.dispose();
    _mobileScannerController.dispose();
  }

  void _handleBarcodes(BarcodeCapture capture) {
    if (_scannerDisabled.value) {
      return;
    }

    for (final barcode in capture.barcodes) {
      if (isPointInPolygon(
        Offset(
          _mobileScannerController.value.size.width / 2,
          _mobileScannerController.value.size.height / 2,
        ),
        barcode.corners,
      )) {
        if (!barcodeDetected) {
          barcodeDetected = true;
          Navigator.of(context).pop(barcode);
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const boxFit = BoxFit.contain;
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          SystemChrome.setPreferredOrientations([...DeviceOrientation.values]);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Picklist scanner')),
        backgroundColor: Colors.black,
        body: StreamBuilder(
          stream: _mobileScannerController.barcodes,
          builder: (context, snapshot) {
            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _scannerDisabled.value = true,
              onPointerUp: (_) => _scannerDisabled.value = false,
              onPointerCancel: (_) => _scannerDisabled.value = false,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _mobileScannerController,
                    errorBuilder: (context, error, child) =>
                        ScannerErrorWidget(error: error),
                    fit: boxFit,
                  ),
                  ValueListenableBuilder(
                    valueListenable: _scannerDisabled,
                    builder: (context, value, child) {
                      return Crosshair(
                        scannerDisabled: value,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
