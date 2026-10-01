import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_authorization_state.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeMobileScannerPlatform platform;

  setUp(() {
    platform = FakeMobileScannerPlatform();
    MobileScannerPlatform.instance = platform;
    MobileScannerController.resetPlatformSessionOwner();
  });

  group('dispose', () {
    test('disposing the only controller disposes the platform', () async {
      final controller = MobileScannerController(autoStart: false)..attach();

      await controller.start();
      await controller.dispose();

      expect(platform.disposeCalls, 1);
    });

    test(
      'disposing a controller that never started does not dispose the '
      'platform while another controller holds the camera session',
      () async {
        final first = MobileScannerController(autoStart: false)..attach();
        await first.start();

        final second = MobileScannerController(autoStart: false);
        await second.dispose();

        expect(platform.disposeCalls, 0);
        expect(platform.stopCalls, 0);
        expect(first.value.isRunning, isTrue);

        await first.dispose();

        expect(platform.disposeCalls, 1);
      },
    );

    test(
      'disposing a stopped controller does not dispose the platform '
      'while another controller holds the camera session',
      () async {
        final first = MobileScannerController(autoStart: false)..attach();
        await first.start();
        await first.stop();

        final second = MobileScannerController(autoStart: false)..attach();
        await second.start();

        await first.dispose();

        expect(platform.disposeCalls, 0);
        expect(second.value.isRunning, isTrue);

        await second.dispose();

        expect(platform.disposeCalls, 1);
      },
    );

    test(
      'disposing all controllers when none hold the camera session '
      'disposes the platform',
      () async {
        final controller = MobileScannerController(autoStart: false)..attach();

        await controller.start();
        await controller.stop();
        await controller.dispose();

        expect(platform.disposeCalls, 1);
      },
    );

    test(
      'a controller disposed while starting releases the platform '
      'once the start completes',
      () async {
        final startGate = Completer<void>();
        platform.startGate = startGate;

        final controller = MobileScannerController(autoStart: false)..attach();
        final start = controller.start();

        await controller.dispose();
        final disposeCallsBeforeStartCompleted = platform.disposeCalls;

        startGate.complete();
        await start;

        expect(platform.disposeCalls, disposeCallsBeforeStartCompleted + 1);
      },
    );

    test(
      'a controller disposed while starting does not take over '
      'the camera session of another controller',
      () async {
        final startGate = Completer<void>();
        platform.startGate = startGate;

        final first = MobileScannerController(autoStart: false)..attach();
        final firstStart = first.start();
        await first.dispose();

        platform.startGate = null;
        final second = MobileScannerController(autoStart: false)..attach();
        await second.start();

        startGate.complete();
        await firstStart;

        final disposeCalls = platform.disposeCalls;
        await second.dispose();

        expect(platform.stopCalls, 0);
        expect(platform.disposeCalls, disposeCalls + 1);
      },
    );
  });

  group('dispose while starting with the method channel', () {
    late MethodChannelMobileScanner channelPlatform;

    setUp(() {
      // Use the iOS response format,
      // which does not need an Android surface producer configuration.
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      channelPlatform = MethodChannelMobileScanner();
      MobileScannerPlatform.instance = channelPlatform;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channelPlatform.methodChannel, null);
    });

    test(
      'the next controller can start after a controller '
      'was disposed while starting',
      () async {
        final firstNativeStart = Completer<void>();
        var nativeStartCalls = 0;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channelPlatform.methodChannel, (
              methodCall,
            ) async {
              switch (methodCall.method) {
                case MethodChannelMobileScanner.kAuthorizationStateMethodName:
                  return MobileScannerAuthorizationState.authorized.rawValue;
                case MethodChannelMobileScanner.kStartCameraMethodName:
                  nativeStartCalls++;
                  if (nativeStartCalls == 1) {
                    await firstNativeStart.future;
                  }

                  return <String, Object?>{
                    'textureId': nativeStartCalls,
                    'cameraDirection': CameraFacing.back.rawValue,
                    'numberOfCameras': 1,
                    'currentTorchState': TorchState.unavailable.rawValue,
                    'size': <String, Object?>{
                      'width': 1920.0,
                      'height': 1080.0,
                    },
                  };
              }

              return null;
            });

        final first = MobileScannerController(autoStart: false)..attach();
        final firstStart = first.start();
        await first.dispose();

        firstNativeStart.complete();
        await firstStart;

        final second = MobileScannerController(autoStart: false)..attach();
        addTearDown(second.dispose);

        await second.start();

        expect(second.value.error, isNull);
        expect(second.value.isRunning, isTrue);
      },
    );
  });
}

class FakeMobileScannerPlatform extends MobileScannerPlatform {
  int disposeCalls = 0;
  int stopCalls = 0;

  /// If set, [start] does not complete until this completer completes.
  Completer<void>? startGate;

  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream =>
      Stream.value(TorchState.unavailable);

  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    await startGate?.future;

    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(200, 200),
      numberOfCameras: 3,
      initialDeviceOrientation: DeviceOrientation.portraitUp,
    );
  }

  @override
  Future<void> stop() {
    stopCalls++;
    return Future.value();
  }

  @override
  Future<void> dispose() {
    disposeCalls++;
    return Future.value();
  }
}
