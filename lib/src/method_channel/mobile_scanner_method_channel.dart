import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';

/// An implementation of [MobileScannerPlatform] that uses method channels.
class MethodChannelMobileScanner extends MobileScannerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'dev.steenbakker.mobile_scanner/scanner/method',
  );

  /// The event channel that sends back scanned barcode events.
  @visibleForTesting
  final eventChannel = const EventChannel(
    'dev.steenbakker.mobile_scanner/scanner/event',
  );

  Stream<Map<Object?, Object?>>? _eventsStream;

  Stream<Map<Object?, Object?>> get eventsStream {
    _eventsStream ??=
        eventChannel.receiveBroadcastStream().cast<Map<Object?, Object?>>();

    return _eventsStream!;
  }

  int? _textureId;

  /// Parse a [BarcodeCapture] from the given [event].
  BarcodeCapture? _parseBarcode(Map<Object?, Object?>? event) {
    if (event == null) {
      return null;
    }

    final Object? data = event['data'];

    if (data == null || data is! List<Object?>) {
      return null;
    }

    final List<Map<Object?, Object?>> barcodes = data.cast<Map<Object?, Object?>>();

    if (Platform.isMacOS) {
      return BarcodeCapture(
        raw: event,
        barcodes: barcodes
            .map(
              (barcode) => Barcode(
                rawValue: barcode['payload'] as String?,
                format: BarcodeFormat.fromRawValue(
                  barcode['symbology'] as int? ?? -1,
                ),
              ),
            )
            .toList(),
      );
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final double? width = event['width'] as double?;
      final double? height = event['height'] as double?;

      return BarcodeCapture(
        raw: data,
        barcodes: barcodes.map(Barcode.fromNative).toList(),
        image: event['image'] as Uint8List?,
        size: width == null || height == null ? Size.zero : Size(width, height),
      );
    }

    throw const MobileScannerException(
      errorCode: MobileScannerErrorCode.genericError,
      errorDetails: MobileScannerErrorDetails(
        message: 'Only Android, iOS and macOS are supported.',
      ),
    );
  }

  @override
  Stream<TorchState> get torchStateStream {
    return eventsStream
        .where((event) => event['name'] == 'torchState')
        .map((event) => TorchState.fromRawValue(event['data'] as int? ?? 0));
  }

  @override
  Stream<double> get zoomScaleStateStream {
    return eventsStream
        .where((event) => event['name'] == 'zoomScaleState')
        .map((event) => event['data'] as double? ?? 0.0);
  }

  @override
  Future<BarcodeCapture?> analyzeImage(String path) async {
    final Map<String, Object?>? result = await methodChannel.invokeMapMethod<String, Object?>(
      'analyzeImage',
      path,
    );

    return _parseBarcode(result);
  }

  @override
  Widget buildCameraView() => Texture(textureId: _textureId!);

  @override
  Future<void> resetZoomScale() async {
    await methodChannel.invokeMethod<void>('resetScale');
  }

  @override
  Future<void> setTorchState(TorchState torchState) async {
    await methodChannel.invokeMethod<void>('torch', torchState.rawValue);
  }

  @override
  Future<void> setZoomScale(double zoomScale) async {
    await methodChannel.invokeMethod<void>('setScale', zoomScale);
  }

  @override
  Future<void> start(CameraFacing cameraDirection) {}

  @override
  Future<void> stop() async {
    await methodChannel.invokeMethod<void>('stop');
  }

  @override
  Future<void> updateScanWindow(Rect? window) async {
    await methodChannel.invokeMethod<void>(
      'updateScanWindow',
      {'rect': window},
    );
  }

  @override
  Future<void> dispose() async {
    await stop();
  }
}
