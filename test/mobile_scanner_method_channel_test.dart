import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$MethodChannelMobileScanner tests', () {
    late MethodChannelMobileScanner scanner;
    late List<MethodCall> methodCalls;

    setUp(() {
      scanner = MethodChannelMobileScanner();
      methodCalls = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(scanner.methodChannel, (call) async {
        methodCalls.add(call);
        return _handleMethodCall(call);
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(scanner.methodChannel, null);
    });

    group('constants', () {
      test('has correct event name constants', () {
        expect(MethodChannelMobileScanner.kBarcodeEventName, 'barcode');
        expect(
          MethodChannelMobileScanner.kBarcodeErrorEventName,
          'MOBILE_SCANNER_BARCODE_ERROR',
        );
        expect(
          MethodChannelMobileScanner.kUnsupportdOperationErrorEventName,
          'MOBILE_SCANNER_UNSUPPORTED_OPERATION',
        );
        expect(MethodChannelMobileScanner.kTorchStateEventName, 'torchState');
        expect(
          MethodChannelMobileScanner.kZoomScaleStateEventName,
          'zoomScaleState',
        );
      });

      test('has correct method name constants', () {
        expect(MethodChannelMobileScanner.kAuthorizationStateMethodName, 'state');
        expect(
          MethodChannelMobileScanner.kRequestAuthorizationMethodName,
          'request',
        );
        expect(
          MethodChannelMobileScanner.kAnalyzeImageMethodName,
          'analyzeImage',
        );
        expect(MethodChannelMobileScanner.kResetScaleMethodName, 'resetScale');
        expect(MethodChannelMobileScanner.kSetScaleMethodName, 'setScale');
        expect(MethodChannelMobileScanner.kSetFocusMethodName, 'setFocus');
        expect(MethodChannelMobileScanner.kStartCameraMethodName, 'start');
        expect(MethodChannelMobileScanner.kStopCameraMethodName, 'stop');
        expect(MethodChannelMobileScanner.kPauseCameraMethodName, 'pause');
        expect(MethodChannelMobileScanner.kToggleTorchMethodName, 'toggleTorch');
        expect(
          MethodChannelMobileScanner.kUpdateScanWindowMethodName,
          'updateScanWindow',
        );
        expect(
          MethodChannelMobileScanner.kGetSupportedLensesMethodName,
          'getSupportedLenses',
        );
      });
    });

    group('buildCameraView', () {
      test('returns SizedBox when textureId is null', () {
        final widget = scanner.buildCameraView();
        expect(widget, isA<SizedBox>());
      });
    });

    group('resetZoomScale', () {
      test('calls correct method', () async {
        await scanner.resetZoomScale();

        expect(methodCalls.length, 1);
        expect(methodCalls[0].method, 'resetScale');
      });
    });

    group('setZoomScale', () {
      test('calls correct method with zoom scale', () async {
        await scanner.setZoomScale(0.5);

        expect(methodCalls.length, 1);
        expect(methodCalls[0].method, 'setScale');
        expect(methodCalls[0].arguments, 0.5);
      });

      test('handles edge values', () async {
        await scanner.setZoomScale(0.0);
        expect(methodCalls[0].arguments, 0.0);

        methodCalls.clear();

        await scanner.setZoomScale(1.0);
        expect(methodCalls[0].arguments, 1.0);
      });
    });

    group('toggleTorch', () {
      test('calls correct method', () async {
        await scanner.toggleTorch();

        expect(methodCalls.length, 1);
        expect(methodCalls[0].method, 'toggleTorch');
      });
    });

    group('stop', () {
      test('calls stop method with force parameter', () async {
        await scanner.stop(force: true);

        expect(methodCalls.length, 1);
        expect(methodCalls[0].method, 'stop');
        expect(methodCalls[0].arguments, {'force': true});
      });

      test('does nothing when textureId is null and force is false', () async {
        await scanner.stop();

        expect(methodCalls, isEmpty);
      });
    });

    group('pause', () {
      test('does nothing when already pausing', () async {
        // First pause
        await scanner.pause();
        expect(methodCalls.length, 1);

        // Second pause should do nothing
        await scanner.pause();
        expect(methodCalls.length, 1);
      });
    });

    group('updateScanWindow', () {
      test('does nothing when textureId is null', () async {
        await scanner.updateScanWindow(const Rect.fromLTWH(0, 0, 100, 100));

        expect(methodCalls, isEmpty);
      });
    });

    group('getSupportedLenses', () {
      test('returns empty set when null is returned', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'getSupportedLenses') {
            return null;
          }
          return null;
        });

        final result = await scanner.getSupportedLenses();

        expect(result, isEmpty);
      });

      test('returns empty set when empty list is returned', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'getSupportedLenses') {
            return <int>[];
          }
          return null;
        });

        final result = await scanner.getSupportedLenses();

        expect(result, isEmpty);
      });

      test('returns correct lens types from raw values', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'getSupportedLenses') {
            return [0, 1, 2, 3]; // any, normal, wide, zoom
          }
          return null;
        });

        final result = await scanner.getSupportedLenses();

        expect(result, contains(CameraLensType.any));
        expect(result, contains(CameraLensType.normal));
        expect(result, contains(CameraLensType.wide));
        expect(result, contains(CameraLensType.zoom));
      });

      test('filters out non-integer values', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'getSupportedLenses') {
            return [0, 'invalid', 1, null, 2];
          }
          return null;
        });

        final result = await scanner.getSupportedLenses();

        expect(result.length, 3);
      });
    });

    group('analyzeImage', () {
      test('returns null when platform returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'analyzeImage') {
            return null;
          }
          return null;
        });

        final result = await scanner.analyzeImage('/path/to/image.png');

        expect(result, isNull);
      });

      test('passes correct parameters without formats', () async {
        late Map<String, Object?> passedArgs;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'analyzeImage') {
            passedArgs = Map<String, Object?>.from(call.arguments as Map);
            return null;
          }
          return null;
        });

        await scanner.analyzeImage('/path/to/image.png');

        expect(passedArgs['filePath'], '/path/to/image.png');
        expect(passedArgs['formats'], isNull);
      });

      test('passes correct parameters with formats', () async {
        late Map<String, Object?> passedArgs;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'analyzeImage') {
            passedArgs = Map<String, Object?>.from(call.arguments as Map);
            return null;
          }
          return null;
        });

        await scanner.analyzeImage(
          '/path/to/image.png',
          formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
        );

        expect(passedArgs['filePath'], '/path/to/image.png');
        expect(passedArgs['formats'], isNotNull);
        expect(
          passedArgs['formats'],
          contains(BarcodeFormat.qrCode.rawValue),
        );
        expect(
          passedArgs['formats'],
          contains(BarcodeFormat.code128.rawValue),
        );
      });

      test('filters out unknown barcode format', () async {
        late Map<String, Object?> passedArgs;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'analyzeImage') {
            passedArgs = Map<String, Object?>.from(call.arguments as Map);
            return null;
          }
          return null;
        });

        await scanner.analyzeImage(
          '/path/to/image.png',
          formats: [BarcodeFormat.qrCode, BarcodeFormat.unknown],
        );

        final formats = passedArgs['formats'] as List;
        expect(formats.length, 1);
        expect(formats, contains(BarcodeFormat.qrCode.rawValue));
      });

      test('throws MobileScannerBarcodeException on barcode error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'analyzeImage') {
            throw PlatformException(
              code: 'MOBILE_SCANNER_BARCODE_ERROR',
              message: 'No barcode found',
            );
          }
          return null;
        });

        expect(
          () => scanner.analyzeImage('/path/to/image.png'),
          throwsA(isA<MobileScannerBarcodeException>()),
        );
      });

      test('throws UnsupportedError on unsupported operation', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'analyzeImage') {
            throw PlatformException(
              code: 'MOBILE_SCANNER_UNSUPPORTED_OPERATION',
              message: 'Not supported',
            );
          }
          return null;
        });

        expect(
          () => scanner.analyzeImage('/path/to/image.png'),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('returns null on other platform exceptions', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'analyzeImage') {
            throw PlatformException(code: 'UNKNOWN_ERROR');
          }
          return null;
        });

        final result = await scanner.analyzeImage('/path/to/image.png');

        expect(result, isNull);
      });
    });

    group('dispose', () {
      test('calls stop even when textureId is null', () async {
        await scanner.dispose();

        // dispose calls updateScanWindow(null) then stop()
        // updateScanWindow does nothing when textureId is null
        // stop() also does nothing when textureId is null (returns early)
        // So no method calls are expected
        expect(methodCalls, isEmpty);
      });
    });

    group('start', () {
      test('throws when already initialized and not pausing', () async {
        // Mock a successful start
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'state') {
            return 1; // authorized
          }
          if (call.method == 'start') {
            return {
              'textureId': 1,
              'cameraDirection': 0,
              'size': {'width': 1920.0, 'height': 1080.0},
              'currentTorchState': 0,
              'numberOfCameras': 2,
              'handlesCropAndRotation': true,
              'naturalDeviceOrientation': 'PORTRAIT_UP',
              'sensorOrientation': 90,
            };
          }
          return null;
        });

        const startOptions = StartOptions(
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          cameraResolution: null,
          detectionSpeed: DetectionSpeed.normal,
          detectionTimeoutMs: 250,
          formats: [],
          returnImage: false,
          torchEnabled: false,
          invertImage: false,
          autoZoom: false,
          initialZoom: null,
        );

        // First start should succeed
        await scanner.start(startOptions);

        // Second start should throw
        expect(
          () => scanner.start(startOptions),
          throwsA(
            isA<MobileScannerException>().having(
              (e) => e.errorCode,
              'errorCode',
              MobileScannerErrorCode.controllerAlreadyInitialized,
            ),
          ),
        );
      });

      test('throws when permission is denied', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'state') {
            return 2; // denied
          }
          if (call.method == 'request') {
            return false; // permission not granted
          }
          return null;
        });

        const startOptions = StartOptions(
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          cameraResolution: null,
          detectionSpeed: DetectionSpeed.normal,
          detectionTimeoutMs: 250,
          formats: [],
          returnImage: false,
          torchEnabled: false,
          invertImage: false,
          autoZoom: false,
          initialZoom: null,
        );

        expect(
          () => scanner.start(startOptions),
          throwsA(
            isA<MobileScannerException>().having(
              (e) => e.errorCode,
              'errorCode',
              MobileScannerErrorCode.permissionDenied,
            ),
          ),
        );
      });

      test('throws when start returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'state') {
            return 1; // authorized
          }
          if (call.method == 'start') {
            return null;
          }
          return null;
        });

        const startOptions = StartOptions(
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          cameraResolution: null,
          detectionSpeed: DetectionSpeed.normal,
          detectionTimeoutMs: 250,
          formats: [],
          returnImage: false,
          torchEnabled: false,
          invertImage: false,
          autoZoom: false,
          initialZoom: null,
        );

        expect(
          () => scanner.start(startOptions),
          throwsA(
            isA<MobileScannerException>().having(
              (e) => e.errorDetails?.message,
              'message',
              'The start method did not return a view configuration.',
            ),
          ),
        );
      });

      test('throws when textureId is null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'state') {
            return 1; // authorized
          }
          if (call.method == 'start') {
            return {
              'cameraDirection': 0,
              'size': {'width': 1920.0, 'height': 1080.0},
            };
          }
          return null;
        });

        const startOptions = StartOptions(
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          cameraResolution: null,
          detectionSpeed: DetectionSpeed.normal,
          detectionTimeoutMs: 250,
          formats: [],
          returnImage: false,
          torchEnabled: false,
          invertImage: false,
          autoZoom: false,
          initialZoom: null,
        );

        expect(
          () => scanner.start(startOptions),
          throwsA(
            isA<MobileScannerException>().having(
              (e) => e.errorDetails?.message,
              'message',
              'The start method did not return a texture id.',
            ),
          ),
        );
      });

      test('handles platform exception during start', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scanner.methodChannel, (call) async {
          if (call.method == 'state') {
            return 1; // authorized
          }
          if (call.method == 'start') {
            throw PlatformException(
              code: 'MOBILE_SCANNER_NO_CAMERA_ERROR',
              message: 'No camera available',
            );
          }
          return null;
        });

        const startOptions = StartOptions(
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          cameraResolution: null,
          detectionSpeed: DetectionSpeed.normal,
          detectionTimeoutMs: 250,
          formats: [],
          returnImage: false,
          torchEnabled: false,
          invertImage: false,
          autoZoom: false,
          initialZoom: null,
        );

        expect(
          () => scanner.start(startOptions),
          throwsA(
            isA<MobileScannerException>().having(
              (e) => e.errorCode,
              'errorCode',
              MobileScannerErrorCode.unsupported,
            ),
          ),
        );
      });
    });
  });
}

Object? _handleMethodCall(MethodCall call) {
  switch (call.method) {
    case 'resetScale':
    case 'setScale':
    case 'toggleTorch':
    case 'stop':
    case 'pause':
    case 'updateScanWindow':
      return null;
    case 'getSupportedLenses':
      return <int>[0, 1];
    default:
      return null;
  }
}
