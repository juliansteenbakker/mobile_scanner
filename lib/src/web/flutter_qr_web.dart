// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:core';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../mobile_scanner.dart';
import 'jsqr.dart';
import 'media.dart';

/// Even though it has been highly modified, the origial implementation has been
/// adopted from https://github.com:treeder/jsqr_flutter
///
/// Copyright 2020 @treeder
/// Copyright 2021 The one with the braid

class WebScanner extends StatefulWidget {
  final Function(Barcode) onDetect;
  final CameraFacing? cameraFacing;

  const WebScanner(
      {Key? key,
      required this.onDetect,
      this.cameraFacing = CameraFacing.front})
      : super(key: key);

  @override
  _WebScannerState createState() => _WebScannerState();

  // need a global for the registerViewFactory
  static html.DivElement vidDiv = html.DivElement();

  static Future<bool> cameraAvailable() async {
    final sources =
        await html.window.navigator.mediaDevices!.enumerateDevices();
    // List<String> vidIds = [];
    var hasCam = false;
    for (final e in sources) {
      if (e.kind == 'videoinput') {
        // vidIds.add(e['deviceId']);
        hasCam = true;
      }
    }
    return hasCam;
  }
}

class _WebScannerState extends State<WebScanner> {
  // Which way the camera is facing
  // late CameraFacing facing;

  // The camera stream to display to the user
  html.MediaStream? _localStream;

  // Check if analyzer is processing barcode
  bool _currentlyProcessing = false;

  // QRViewControllerWeb? _controller;

  // Set size of the webview
  // Size _size = const Size(0, 0);

  // TODO: Timer for capture?
  Timer? timer;

  // String? code;

  // TODO: Error message if error
  String? _errorMsg;

  // Video element to be played on
  html.VideoElement video = html.VideoElement();

  // ID of the video feed
  String viewID =
      'WebScanner-' + DateTime.now().millisecondsSinceEpoch.toString();

  // final StreamController<Barcode> _scanUpdateController =
  //     StreamController<Barcode>();

  // Timer for interval capture
  Timer? _frameIntervall;

  @override
  void initState() {
    super.initState();
    // facing = widget.cameraFacing ?? CameraFacing.front;
    WebScanner.vidDiv.children = [video];

    // ignore: UNDEFINED_PREFIXED_NAME
    ui.platformViewRegistry
        .registerViewFactory(viewID, (int id) => WebScanner.vidDiv);

    // giving JavaScipt some time to process the DOM changes
    Timer(const Duration(milliseconds: 500), () {
      start();
    });
  }

  /// Initialize camera and capture frame
  Future start() async {
    await _startVideoStream();
    _frameIntervall?.cancel();
    _frameIntervall =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _captureFrame();
    });
  }

  void cancel() {
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }
    if (_currentlyProcessing) {
      _stopVideoStream();
    }
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }

  /// Starts a video stream if not started already
  Future<void> _startVideoStream() async {
    // Check if stream is running
    if (_localStream != null) return;

    try {
      // Check if browser supports multiple camera's and set if supported
      Map? capabilities =
          html.window.navigator.mediaDevices?.getSupportedConstraints();
      if (capabilities != null && capabilities['facingMode']) {
        UserMediaOptions constraints = UserMediaOptions(
            video: VideoOptions(
          facingMode: (widget.cameraFacing == CameraFacing.front
              ? 'user'
              : 'environment'),
          width: {'ideal': 4096},
          height: {'ideal': 2160},
        ));

        _localStream =
            await html.window.navigator.getUserMedia(video: constraints);
      } else {
        _localStream = await html.window.navigator.getUserMedia(video: true);
      }

      video.srcObject = _localStream;

      // required to tell iOS safari we don't want fullscreen
      video.setAttribute('playsinline', 'true');

      // TODO: Check controller
      // if (_controller == null) {
      //   _controller = QRViewControllerWeb(this);
      //   widget.onPlatformViewCreated(_controller!);
      // }

      await video.play();
    } catch (e) {
      cancel();
      setState(() {
        _errorMsg = e.toString();
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _currentlyProcessing = true;
    });
  }

  Future<void> _stopVideoStream() async {
    try {
      // Stop the camera stream
      _localStream!.getTracks().forEach((track) {
        if (track.readyState == 'live') {
          track.stop();
        }
      });

      video.srcObject = null;
      _localStream = null;
    } catch (e) {
      debugPrint('Failed to stop stream: $e');
    }
  }

  Future<dynamic> _captureFrame() async {
    if (_localStream == null) return null;
    final canvas = html.CanvasElement(width: video.videoWidth, height: video.videoHeight);
    final ctx = canvas.context2D;

    ctx.drawImage(video, 0, 0);
    final imgData = ctx.getImageData(0, 0, canvas.width!, canvas.height!);

    // final size =
    //     Size(canvas.width?.toDouble() ?? 0, canvas.height?.toDouble() ?? 0);
    // if (size != _size) {
    //   setState(() {
    //     _setCanvasSize(size);
    //   });
    // }
    // debugPrint('img.data: ${imgData.data}');
    final code = jsQR(imgData.data, canvas.width, canvas.height);
    // ignore: unnecessary_null_comparison
    if (code != null) {
      debugPrint('CODE: $code');
    //   widget.onDetect(Barcode(rawValue: code.data));
      // print('Barcode: ${code.data}');
      // _scanUpdateController
      //     .add(Barcode(rawValue: code.data));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMsg != null) {
      return Center(child: Text(_errorMsg!));
    }
    if (_localStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: FittedBox(
            child: SizedBox(
                width: video.videoWidth.toDouble(),
                height: video.videoHeight.toDouble(),
                child: HtmlElementView(viewType: viewID))));
  }
}
