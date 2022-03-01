import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'objects/barcode_utility.dart';

extension MobileScannerToolsFromFile on MobileScannerTools {
  static const MethodChannel _methodChannel =
      MethodChannel('dev.steenbakker.mobile_scanner/scanner/method');
  Future<List<Barcode>?> readFromFile(String path) async {
    final result = await _methodChannel.invokeMapMethod('fromFile', path);
    final type = result?['type'];
    switch (type) {
      case "GoogleMLKitVision":
        final dataList = result?['data'] as List;
        return dataList.map((val) => Barcode.fromNative(val)).toList();
      case "AppleVision":
        final dataList = result?['data'] as List;

        return dataList
            .map((data) => Barcode(
                  format: toFormat(data['format']),
                  rawValue: data["payload"],
                ))
            .toList();
      default:
        throw Exception('mobile_scanner: Bad message receive from native');
    }
  }
}
