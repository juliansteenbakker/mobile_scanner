import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';

/// A web implementation of the MobileScannerPlatform of the MobileScanner plugin.
class MobileScannerWeb extends MobileScannerPlatform {
  /// Constructs a [MobileScannerWeb] instance.
  MobileScannerWeb();

  static void registerWith(Registrar registrar) {
    MobileScannerPlatform.instance = MobileScannerWeb();
  }
}
