import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/web/jsqr.dart';
import 'package:mobile_scanner/src/web/media.dart';

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
    WidgetsFlutterBinding.ensureInitialized();

    channel.setMethodCallHandler(instance.handleMethodCall);
    event.setController(instance.controller);
  }

  // Controller to send events back to the framework
  StreamController controller = StreamController.broadcast();

  // The video stream. Will be initialized later to see which camera needs to be used.
  html.MediaStream? _localStream;
  html.VideoElement video = html.VideoElement();

  // ID of the video feed
  String viewID = 'WebScanner-${DateTime.now().millisecondsSinceEpoch}';

  // Determine wether device has flas
  bool hasFlash = false;

  // Timer used to capture frames to be analyzed
  Timer? _frameInterval;

  html.DivElement vidDiv = html.DivElement();

  /// Handle incomming messages
  Future<dynamic> handleMethodCall(MethodCall call) async {
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
    if (hasFlash) {
      final track = _localStream?.getVideoTracks();
      await track!.first.applyConstraints({
        'advanced': {'torch': arguments == 1}
      });
    } else {
      controller.addError('Device has no flash');
    }
  }

  /// Starts the video stream and the scanner
  Future<Map> _start(Map arguments) async {
    vidDiv.children = [video];

    var cameraFacing = CameraFacing.front;
    if (arguments.containsKey('facing')) {
      cameraFacing = CameraFacing.values[arguments['facing'] as int];
    }

    // See https://github.com/flutter/flutter/issues/41563
    // ignore: UNDEFINED_PREFIXED_NAME, avoid_dynamic_calls
    ui.platformViewRegistry.registerViewFactory(
      viewID,
      (int id) => vidDiv
        ..style.width = '100%'
        ..style.height = '100%',
    );

    // Check if stream is running
    if (_localStream != null) {
      return {
        'ViewID': viewID,
        'videoWidth': video.videoWidth,
        'videoHeight': video.videoHeight
      };
    }

    try {
      // Check if browser supports multiple camera's and set if supported
      final Map? capabilities =
          html.window.navigator.mediaDevices?.getSupportedConstraints();
      if (capabilities != null && capabilities['facingMode'] as bool) {
        final constraints = {
          'video': VideoOptions(
            facingMode:
                cameraFacing == CameraFacing.front ? 'user' : 'environment',
          )
        };

        _localStream =
            await html.window.navigator.mediaDevices?.getUserMedia(constraints);
      } else {
        _localStream = await html.window.navigator.mediaDevices
            ?.getUserMedia({'video': true});
      }

      video.srcObject = _localStream;

      // TODO: fix flash light. See https://github.com/dart-lang/sdk/issues/48533
      // final track = _localStream?.getVideoTracks();
      // if (track != null) {
      //   final imageCapture = html.ImageCapture(track.first);
      //   final photoCapabilities = await imageCapture.getPhotoCapabilities();
      // }

      // required to tell iOS safari we don't want fullscreen
      video.setAttribute('playsinline', 'true');

      await video.play();

      // Then capture a frame to be analyzed every 200 miliseconds
      _frameInterval =
          Timer.periodic(const Duration(milliseconds: 200), (timer) {
        _captureFrame();
      });

      return {
        'ViewID': viewID,
        'videoWidth': video.videoWidth,
        'videoHeight': video.videoHeight,
        'torchable': hasFlash
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
    try {
      // Stop the camera stream
      _localStream?.getTracks().forEach((track) {
        if (track.readyState == 'live') {
          track.stop();
        }
      });
    } catch (e) {
      debugPrint('Failed to stop stream: $e');
    }

    video.srcObject = null;
    _localStream = null;
    _frameInterval?.cancel();
    _frameInterval = null;
  }

  /// Captures a frame and analyzes it for QR codes
  Future<dynamic> _captureFrame() async {
    if (_localStream == null) return null;
    final canvas =
        html.CanvasElement(width: video.videoWidth, height: video.videoHeight);
    final ctx = canvas.context2D;

    ctx.drawImage(video, 0, 0);
    final imgData = ctx.getImageData(0, 0, canvas.width!, canvas.height!);

    final code = jsQR(imgData.data, canvas.width, canvas.height);
    if (code != null) {
      controller.add({'name': 'barcodeWeb', 'data': code.data});
    }
  }
}
