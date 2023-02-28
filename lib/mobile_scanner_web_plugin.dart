import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:mobile_scanner/mobile_scanner_web.dart';
import 'package:mobile_scanner/src/barcode_utility.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/web/utils.dart';

/// This plugin is the web implementation of mobile_scanner.
/// It only supports QR codes.
class MobileScannerWebPlugin {
  static void registerWith(Registrar registrar) {
    final PluginEventChannel event = PluginEventChannel(
      'dev.steenbakker.mobile_scanner/scanner/event',
      const StandardMethodCodec(),
      registrar,
    );
    final MethodChannel channel = MethodChannel(
      'dev.steenbakker.mobile_scanner/scanner/method',
      const StandardMethodCodec(),
      registrar,
    );
    final MobileScannerWebPlugin instance = MobileScannerWebPlugin();

    _jsLibrariesLoadingFuture = injectJSLibraries(barCodeReader.jsLibraries);

    channel.setMethodCallHandler(instance.handleMethodCall);
    event.setController(instance.controller);
  }

  // Controller to send events back to the framework
  StreamController controller = StreamController.broadcast();

  // ID of the video feed
  String viewID = 'WebScanner-${DateTime.now().millisecondsSinceEpoch}';

  static final html.DivElement vidDiv = html.DivElement();

  /// Represents barcode reader library.
  /// Change this property if you want to use a custom implementation.
  ///
  /// Example of using the jsQR library:
  /// void main() {
  ///   if (kIsWeb) {
  ///     MobileScannerWebPlugin.barCodeReader =
  ///         JsQrCodeReader(videoContainer: MobileScannerWebPlugin.vidDiv);
  ///   }
  ///   runApp(const MaterialApp(home: MyHome()));
  /// }
  static WebBarcodeReaderBase barCodeReader =
      ZXingBarcodeReader(videoContainer: vidDiv);
  StreamSubscription? _barCodeStreamSubscription;

  static late Future _jsLibrariesLoadingFuture;

  /// Handle incomming messages
  Future<dynamic> handleMethodCall(MethodCall call) async {
    await _jsLibrariesLoadingFuture;
    switch (call.method) {
      case 'start':
        return _start(call.arguments as Map);
      case 'torch':
        return _torch(call.arguments);
      case 'stop':
        return cancel();
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: "The mobile_scanner plugin for web doesn't implement "
              "the method '${call.method}'",
        );
    }
  }

  /// Can enable or disable the flash if available
  Future<void> _torch(arguments) async {
    barCodeReader.toggleTorch(enabled: arguments == 1);
  }

  /// Starts the video stream and the scanner
  Future<Map> _start(Map arguments) async {
    var cameraFacing = CameraFacing.front;
    if (arguments.containsKey('facing')) {
      cameraFacing = CameraFacing.values[arguments['facing'] as int];
    }

    // See https://github.com/flutter/flutter/issues/41563
    // ignore: UNDEFINED_PREFIXED_NAME, avoid_dynamic_calls
    ui.platformViewRegistry.registerViewFactory(
      viewID,
      (int id) {
        return vidDiv
          ..style.width = '100%'
          ..style.height = '100%';
      },
    );

    // Check if stream is running
    if (barCodeReader.isStarted) {
      final hasTorch = await barCodeReader.hasTorch();
      return {
        'ViewID': viewID,
        'videoWidth': barCodeReader.videoWidth,
        'videoHeight': barCodeReader.videoHeight,
        'torchable': hasTorch,
      };
    }
    try {
      List<BarcodeFormat>? formats;
      if (arguments.containsKey('formats')) {
        formats = (arguments['formats'] as List)
            .cast<int>()
            .map((e) => toFormat(e))
            .toList();
      }
      final Duration? detectionTimeout;
      if (arguments.containsKey('timeout')) {
        detectionTimeout = Duration(milliseconds: arguments['timeout'] as int);
      } else {
        detectionTimeout = null;
      }
      await barCodeReader.start(
        cameraFacing: cameraFacing,
        formats: formats,
        detectionTimeout: detectionTimeout,
      );

      _barCodeStreamSubscription =
          barCodeReader.detectBarcodeContinuously().listen((code) {
        if (code != null) {
          controller.add({
            'name': 'barcodeWeb',
            'data': {
              'rawValue': code.rawValue,
              'rawBytes': code.rawBytes,
              'format': code.format.rawValue,
            },
          });
        }
      });
      final hasTorch = await barCodeReader.hasTorch();

      if (hasTorch && arguments.containsKey('torch')) {
        barCodeReader.toggleTorch(enabled: arguments['torch'] as bool);
      }

      return {
        'ViewID': viewID,
        'videoWidth': barCodeReader.videoWidth,
        'videoHeight': barCodeReader.videoHeight,
        'torchable': hasTorch,
      };
    } catch (e) {
      throw PlatformException(code: 'MobileScannerWeb', message: '$e');
    }
  }

  /// Check if any camera's are available
  static Future<bool> cameraAvailable() async {
    final sources =
        await html.window.navigator.mediaDevices!.enumerateDevices();
    for (final e in sources) {
      // TODO:
      // ignore: avoid_dynamic_calls
      if (e.kind == 'videoinput') {
        return true;
      }
    }
    return false;
  }

  /// Stops the video feed and analyzer
  Future<void> cancel() async {
    barCodeReader.stop();
    await _barCodeStreamSubscription?.cancel();
    _barCodeStreamSubscription = null;
  }
}
