import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:ui';

import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/barcode_type.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/web/barcode_detector/barcode_detector_js.dart';
import 'package:mobile_scanner/src/web/barcode_reader.dart';
import 'package:mobile_scanner/src/web/media_track_constraints_delegate.dart';
import 'package:mobile_scanner/src/web/media_track_extension.dart';
import 'package:web/web.dart' as web;

/// A barcode reader that uses the native browser BarcodeDetector API
/// (part of the W3C Shape Detection API).
///
/// Supported browsers: Chrome / Edge 83+, Safari 17+.
/// Firefox does not support this API, use `ZXingWasmBarcodeReader` as a
/// fallback.
final class BarcodeDetectorReader extends BarcodeReader {
  /// Construct a new [BarcodeDetectorReader] instance.
  BarcodeDetectorReader();

  /// Returns `true` when the BarcodeDetector API is available and reports at
  /// least one supported format.
  static Future<bool> isSupported() => isBarcodeDetectorSupported();

  web.HTMLVideoElement? _videoElement;
  web.MediaStream? _videoStream;

  NativeBarcodeDetector? _detector;

  Rect? _scanWindow;
  int _timeBetweenScansMs = 1000;

  void Function(web.MediaTrackSettings)? _onMediaTrackSettingsChanged;

  final MediaTrackConstraintsDelegate _mediaTrackConstraintsDelegate =
      const MediaTrackConstraintsDelegate();

  Timer? _decodeTimer;

  // Guard against overlapping detect() calls.
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

  /// BarcodeDetector is a native browser API, no external script to load.
  @override
  Future<void> maybeLoadLibrary({String? alternateScriptUrl}) async {}

  @override
  Future<void> start(
    StartOptions options, {
    required web.HTMLVideoElement videoElement,
    required web.MediaStream videoStream,
  }) async {
    _videoElement = videoElement;
    _videoStream = videoStream;
    _timeBetweenScansMs = options.detectionTimeoutMs;

    final formats = [
      for (final f in options.formats)
        if (f != BarcodeFormat.unknown) f,
    ];

    _detector = _buildDetector(formats);

    // Attach the stream to the video element and start playback.
    videoElement.srcObject = videoStream;
    await videoElement.play().toDart;

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
    _detector = null;
  }

  NativeBarcodeDetector _buildDetector(List<BarcodeFormat> formats) {
    final detectAll =
        formats.isEmpty || formats.contains(BarcodeFormat.all);

    if (detectAll) {
      return NativeBarcodeDetector();
    }

    final strs = [
      for (final f in formats)
        if (f.toBarcodeDetectorString case final s?) s,
    ];

    if (strs.isEmpty) {
      return NativeBarcodeDetector();
    }

    return NativeBarcodeDetector.withOptions(
      BarcodeDetectorInit(
        formats: strs.map((s) => s.toJS).toList().toJS,
      ),
    );
  }

  void _startDecodeLoop(StreamController<BarcodeCapture> controller) {
    _decodeTimer?.cancel();

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

  Future<void> _decodeFrame(
    StreamController<BarcodeCapture> controller,
  ) async {
    final video = _videoElement;
    final detector = _detector;

    if (video == null || detector == null) return;
    if (controller.isClosed) return;
    if (video.paused) return;

    final vw = video.videoWidth;
    final vh = video.videoHeight;
    if (vw == 0 || vh == 0) return;

    final jsResults = await detector.detect(video).toDart;
    final results = jsResults.toDart;
    if (results.isEmpty || controller.isClosed) return;

    final barcodes = <Barcode>[];

    for (final result in results) {
      var barcode = _resultToBarcode(result);

      // Scan-window check in raw camera coordinates (percentage space),
      // before mirroring, matching the percentage rect from the Flutter layer.
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

  Barcode _resultToBarcode(DetectedBarcode result) {
    final pts = result.cornerPoints.toDart;
    final corners = [for (final p in pts) Offset(p.x, p.y)];

    return Barcode(
      corners: corners,
      format: result.format.toBarcodeFormat,
      displayValue: result.rawValue,
      rawValue: result.rawValue,
      size: _computeSize(corners),
      type: BarcodeType.text,
    );
  }

  Size _computeSize(List<Offset> corners) {
    if (corners.length != 4) return Size.zero;
    final xs = corners.map((c) => c.dx);
    final ys = corners.map((c) => c.dy);
    return Size(
      xs.reduce((a, b) => a > b ? a : b) - xs.reduce((a, b) => a < b ? a : b),
      ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b),
    );
  }

  /// Returns true if the full bounding box of [barcode] (normalized to [0, 1]
  /// in camera texture space) lies within the scan window.
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
  bool _shouldMirrorX() {
    final tracks = _videoStream?.getVideoTracks().toDart;
    if (tracks == null || tracks.isEmpty) return false;
    final facingMode = tracks.first.getSettings().facingModeNullable?.toDart;
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
    final reordered = mirrored.length == 4
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
