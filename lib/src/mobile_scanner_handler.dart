import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/src/objects/preview_details.dart';

import 'objects/barcode_formats.dart';

enum FrameRotation { none, ninetyCC, oneeighty, twoseventyCC }

const _defaultBarcodeFormats = [
  BarcodeFormats.ALL_FORMATS,
];

typedef QRCodeHandler = void Function(String? qr);

class MobileScannerHandler {
  static const MethodChannel _channel =
      MethodChannel('dev.steenbakker.mobile_scanner/scanner');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static bool rearLens = true;
  static bool manualFocus = false;

  //Set target size before starting
  static Future<PreviewDetails> start({
    required int width,
    required int height,
    required QRCodeHandler qrCodeHandler,
    List<BarcodeFormats>? formats = _defaultBarcodeFormats,
  }) async {
    final _formats = formats ?? _defaultBarcodeFormats;
    assert(_formats.isNotEmpty);

    List<String> formatStrings = _formats
        .map((format) => format.toString().split('.')[1])
        .toList(growable: false);

    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'qrRead':
          assert(call.arguments is String);
          qrCodeHandler(call.arguments);
          break;
        default:
          debugPrint("QrChannelHandler: unknown method call received at "
              "${call.method}");
      }
    });

    var details = await _channel.invokeMethod('start', {
      'targetWidth': width,
      'targetHeight': height,
      'heartbeatTimeout': 0,
      'formats': formatStrings,
      'rearLens': rearLens,
      'manualFocus': manualFocus
    });

    assert(details is Map<dynamic, dynamic>);

    int? textureId = details["textureId"];
    num? orientation = details["surfaceOrientation"];
    num? surfaceHeight = details["surfaceHeight"];
    num? surfaceWidth = details["surfaceWidth"];

    return PreviewDetails(surfaceWidth, surfaceHeight, orientation, textureId);
  }

  static Future switchCamera() {
    return _channel.invokeMethod('switch').catchError(print);
  }

  static Future toggleFlash() {
    return _channel.invokeMethod('toggleFlash').catchError(print);
  }

  static Future stop() {
    _channel.setMethodCallHandler(null);
    return _channel.invokeMethod('stop').catchError(print);
  }

  static Future heartbeat() {
    return _channel.invokeMethod('heartbeat').catchError(print);
  }

  static Future<List<List<int>>?> getSupportedSizes() {
    return _channel.invokeMethod('getSupportedSizes').catchError(print)
        as Future<List<List<int>>?>;
  }
}
