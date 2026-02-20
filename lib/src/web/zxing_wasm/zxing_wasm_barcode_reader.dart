import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/web/barcode_reader.dart';
import 'package:mobile_scanner/src/web/media_track_constraints_delegate.dart';
import 'package:mobile_scanner/src/web/media_track_extension.dart';
import 'package:mobile_scanner/src/web/zxing_wasm/zxing_wasm_result.dart';
import 'package:web/web.dart' as web;

/// Canvas 2D context creation attributes.
///
/// Setting `willReadFrequently` to `true` tells the browser to optimise the
/// backing store for repeated `getImageData` calls, avoiding GPU readback.
@JS()
extension type _CanvasContextAttributes._(JSObject _) implements JSObject {
  external factory _CanvasContextAttributes({bool willReadFrequently});
}

/// A barcode reader that uses zxing-wasm (zxing-cpp compiled to WebAssembly).
///
/// Frames are extracted by drawing the video element onto an off-screen canvas
/// on each tick, then passed to `ZXingWasmModule.readBarcodesFromImageData`.
///
/// The IIFE build is loaded from jsDelivr. Once loaded it exposes
/// `window.ZXingWASM`; the WASM binary is lazy-fetched on the first call to
/// `readBarcodesFromImageData`.
final class ZXingWasmBarcodeReader extends BarcodeReader {
  /// Construct a new [ZXingWasmBarcodeReader] instance.
  ZXingWasmBarcodeReader();

  @override
  String get scriptId => 'mobile-scanner-zxing-wasm';

  @override
  String get scriptUrl =>
      'https://cdn.jsdelivr.net/npm/zxing-wasm@2/dist/iife/reader/index.js';

  web.HTMLVideoElement? _videoElement;
  web.MediaStream? _videoStream;
  web.HTMLCanvasElement? _canvas;
  web.CanvasRenderingContext2D? _ctx;

  Rect? _scanWindow;
  int _timeBetweenScansMs = 1000;
  List<BarcodeFormat> _formats = const [];

  void Function(web.MediaTrackSettings)? _onMediaTrackSettingsChanged;

  final MediaTrackConstraintsDelegate _mediaTrackConstraintsDelegate =
      const MediaTrackConstraintsDelegate();

  Timer? _decodeTimer;

  // Guard against overlapping decode calls when a frame takes longer to
  // process than the configured interval.
  bool _isDecoding = false;

  @override
  bool get isScanning => _videoStream != null;

  @override
  Size get videoSize {
    final v = _videoElement;
    if (v == null) return Size.zero;
    return Size(v.videoWidth.toDouble(), v.videoHeight.toDouble());
  }

  @override
  web.MediaStream? get videoStream => _videoStream;

  @override
  void updateScanWindow(Rect? window) => _scanWindow = window;

  @override
  void setMediaTrackSettingsListener(
    void Function(web.MediaTrackSettings) listener,
  ) {
    _onMediaTrackSettingsChanged ??= listener;
  }

  @override
  Future<void> start(
    StartOptions options, {
    required web.HTMLVideoElement videoElement,
    required web.MediaStream videoStream,
  }) async {
    _videoElement = videoElement;
    _videoStream = videoStream;
    _timeBetweenScansMs = options.detectionTimeoutMs;
    _formats = [
      for (final f in options.formats)
        if (f != BarcodeFormat.unknown) f,
    ];

    // Attach the stream to the video element and start playback.
    videoElement.srcObject = videoStream;
    await videoElement.play().toDart;

    // Off-screen canvas used to extract ImageData from each video frame.
    // willReadFrequently: true tells the browser to optimise for repeated
    // getImageData calls, avoiding the GPU-readback warning.
    _canvas = web.HTMLCanvasElement();
    _ctx =
        _canvas!.getContext(
              '2d',
              _CanvasContextAttributes(willReadFrequently: true),
            )
            as web.CanvasRenderingContext2D?;

    final settings = _mediaTrackConstraintsDelegate.getSettings(videoStream);
    if (settings != null) {
      _onMediaTrackSettingsChanged?.call(settings);
    }
  }

  @override
  bool? get paused => _videoElement?.paused;

  @override
  void pause() => _videoElement?.pause();

  @override
  Future<void> resume() async {
    await _videoElement?.play().toDart;
  }

  @override
  Stream<BarcodeCapture> detectBarcodes() {
    final controller = StreamController<BarcodeCapture>();

    controller
      ..onListen = () {
        _startDecodeLoop(controller);
      }
      ..onCancel = () async {
        _stopDecodeLoop();
        await controller.close();
      };

    return controller.stream;
  }

  @override
  Future<void> stop() async {
    _stopDecodeLoop();
    _isDecoding = false;
    _onMediaTrackSettingsChanged = null;
    _scanWindow = null;
    _videoElement = null;
    _videoStream = null;
    _canvas = null;
    _ctx = null;
  }

  void _startDecodeLoop(StreamController<BarcodeCapture> controller) {
    _decodeTimer?.cancel();

    // For unrestricted / zero-timeout mode, clamp to ~60 fps so we don't spin
    // the timer as fast as the event loop allows.
    final interval = Duration(
      milliseconds: _timeBetweenScansMs > 0 ? _timeBetweenScansMs : 16,
    );

    _decodeTimer = Timer.periodic(interval, (_) async {
      if (_isDecoding) return;
      _isDecoding = true;
      try {
        await _decodeFrame(controller);
      } on Object catch (_) {
        // Swallow per-frame errors so the loop keeps running.
      } finally {
        _isDecoding = false;
      }
    });
  }

  void _stopDecodeLoop() {
    _decodeTimer?.cancel();
    _decodeTimer = null;
  }

  Future<void> _decodeFrame(StreamController<BarcodeCapture> controller) async {
    final video = _videoElement;
    final canvas = _canvas;
    final ctx = _ctx;

    if (video == null || canvas == null || ctx == null) return;
    if (controller.isClosed) return;
    if (video.paused) return;

    final vw = video.videoWidth;
    final vh = video.videoHeight;
    if (vw == 0 || vh == 0) return;

    // Keep the canvas in sync with the video resolution.
    if (canvas.width != vw || canvas.height != vh) {
      canvas
        ..width = vw
        ..height = vh;
    }

    // Capture the current video frame.
    ctx.drawImage(video, 0, 0);
    final imageData = ctx.getImageData(0, 0, vw, vh);

    final jsResults =
        await zxingWasmModule
            .readBarcodesFromImageData(imageData, _buildReaderOptions())
            .toDart;

    final results = jsResults.toDart;
    if (results.isEmpty || controller.isClosed) return;

    final barcodes = <Barcode>[];

    for (final result in results) {
      if (!result.isValid) continue;

      var barcode = result.toBarcode;

      // Scan-window check uses raw camera coordinates (percentage space),
      // before mirroring, matching the percentage rect from the Flutter
      // layer.
      if (!_isInsideScanWindow(barcode)) continue;

      // Mirror corners for display after the scan-window check.
      if (_shouldMirrorX()) {
        barcode = _mirrorBarcodeX(barcode, vw.toDouble());
      }

      barcodes.add(barcode);
    }

    if (barcodes.isEmpty || controller.isClosed) return;

    controller.add(BarcodeCapture(barcodes: barcodes, size: videoSize));
  }

  ZXingWasmReaderOptions _buildReaderOptions() {
    final detectAll = _formats.isEmpty || _formats.contains(BarcodeFormat.all);

    if (!detectAll) {
      final formatStrs = <JSString>[
        for (final f in _formats)
          if (f.toZXingWasmString case final s?) s.toJS,
      ];

      if (formatStrs.isNotEmpty) {
        return ZXingWasmReaderOptions.withFormats(
          formats: formatStrs.toJS,
          tryHarder: true,
          tryRotate: true,
          tryInvert: false,
        );
      }
    }

    // Omit the formats key entirely so zxing-wasm detects all formats.
    // Passing formats: null causes a crash inside the WASM module.
    return ZXingWasmReaderOptions(
      tryHarder: true,
      tryRotate: true,
      tryInvert: false,
    );
  }

  /// Returns true if the full bounding box of [barcode] (normalized to [0, 1]
  /// in camera texture space) lies within the scan window.
  ///
  /// The scan window from the Flutter layer is already a normalized percentage
  /// [Rect] (values in [0, 1]) relative to the camera texture, produced by
  /// `ScanWindowUtils.calculateScanWindowRelativeToTextureInPercentage`.
  bool _isInsideScanWindow(Barcode barcode) {
    final window = _scanWindow;
    if (window == null) return true;

    final corners = barcode.corners;
    if (corners.length != 4) return true;

    final vw = videoSize.width;
    final vh = videoSize.height;
    if (vw <= 0 || vh <= 0) return true;

    final minX = corners.map((c) => c.dx).reduce(math.min) / vw;
    final maxX = corners.map((c) => c.dx).reduce(math.max) / vw;
    final minY = corners.map((c) => c.dy).reduce(math.min) / vh;
    final maxY = corners.map((c) => c.dy).reduce(math.max) / vh;
    final barcodeRect = Rect.fromLTRB(minX, minY, maxX, maxY);

    return barcodeRect.left >= window.left &&
        barcodeRect.top >= window.top &&
        barcodeRect.right <= window.right &&
        barcodeRect.bottom <= window.bottom;
  }

  /// Returns true when the video preview is displayed mirrored (CSS
  /// `scaleX(-1)`), meaning the barcode corners must be flipped to match the
  /// visual position.
  ///
  /// Must stay in sync with the logic in `_maybeFlipVideoPreview` in
  /// `MobileScannerWeb`.
  bool _shouldMirrorX() {
    final tracks = _videoStream?.getVideoTracks().toDart;
    if (tracks == null || tracks.isEmpty) return false;
    final facingMode = tracks.first.getSettings().facingModeNullable?.toDart;
    // Mirror for front camera on mobile, and always on desktop (facingMode is
    // null on desktop since cameras have no hardware facing mode).
    return facingMode == 'user' || facingMode == null;
  }

  /// Returns a copy of [barcode] with all corner x-coordinates mirrored
  /// relative to [videoWidth].
  Barcode _mirrorBarcodeX(Barcode barcode, double videoWidth) {
    final corners = barcode.corners;
    if (corners.isEmpty) return barcode;

    final mirrored =
        corners.map((c) => Offset(videoWidth - c.dx, c.dy)).toList();

    // Mirroring x reverses the clockwise winding order from
    // [TL, TR, BR, BL] to [TR_m, TL_m, BL_m, BR_m].
    // Swap TL↔TR and BL↔BR to restore [TL_m, TR_m, BR_m, BL_m].
    final reordered =
        mirrored.length == 4
            ? [mirrored[1], mirrored[0], mirrored[3], mirrored[2]]
            : mirrored;

    return Barcode(
      corners: reordered,
      format: barcode.format,
      displayValue: barcode.displayValue,
      // Populate deprecated rawBytes for backward compatibility.
      // ignore: deprecated_member_use_from_same_package
      rawBytes: barcode.rawBytes,
      rawDecodedBytes: barcode.rawDecodedBytes,
      rawValue: barcode.rawValue,
      size: barcode.size,
      type: barcode.type,
    );
  }
}
