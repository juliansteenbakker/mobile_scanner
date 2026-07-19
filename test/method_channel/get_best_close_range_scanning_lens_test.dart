import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getBestCloseRangeScanningLens', () {
    late MethodChannelMobileScanner platform;

    setUp(() {
      platform = MethodChannelMobileScanner();
      MobileScannerPlatform.instance = platform;
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, null);
    });

    test('returns normal lens for raw value 0', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner
                    .kGetBestCloseRangeScanningLensMethodName) {
              return 0;
            }
            return null;
          });

      final result = await platform.getBestCloseRangeScanningLens();

      expect(result, CameraLensType.normal);
    });

    test('returns wide lens for raw value 1', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner
                    .kGetBestCloseRangeScanningLensMethodName) {
              return 1;
            }
            return null;
          });

      final result = await platform.getBestCloseRangeScanningLens();

      expect(result, CameraLensType.wide);
    });

    test('returns zoom lens for raw value 2', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner
                    .kGetBestCloseRangeScanningLensMethodName) {
              return 2;
            }
            return null;
          });

      final result = await platform.getBestCloseRangeScanningLens();

      expect(result, CameraLensType.zoom);
    });

    test('returns null when the device has no camera', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner
                    .kGetBestCloseRangeScanningLensMethodName) {
              return null;
            }
            return null;
          });

      final result = await platform.getBestCloseRangeScanningLens();

      expect(result, isNull);
    });

    test('passes facing back (rawValue 1) to platform channel', () async {
      MethodCall? capturedCall;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner
                    .kGetBestCloseRangeScanningLensMethodName) {
              capturedCall = methodCall;
              return 0;
            }
            return null;
          });

      await platform.getBestCloseRangeScanningLens();

      expect(capturedCall, isNotNull);
      expect(capturedCall!.arguments, equals({'facing': 1}));
    });

    test('passes facing front (rawValue 0) to platform channel', () async {
      MethodCall? capturedCall;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner
                    .kGetBestCloseRangeScanningLensMethodName) {
              capturedCall = methodCall;
              return 0;
            }
            return null;
          });

      await platform.getBestCloseRangeScanningLens(facing: CameraFacing.front);

      expect(capturedCall, isNotNull);
      expect(capturedCall!.arguments, equals({'facing': 0}));
    });

    test('calls correct method on platform channel', () async {
      final methodCalls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            methodCalls.add(methodCall);
            if (methodCall.method ==
                MethodChannelMobileScanner
                    .kGetBestCloseRangeScanningLensMethodName) {
              return 0;
            }
            return null;
          });

      await platform.getBestCloseRangeScanningLens();

      expect(methodCalls, hasLength(1));
      expect(
        methodCalls.first.method,
        MethodChannelMobileScanner.kGetBestCloseRangeScanningLensMethodName,
      );
    });
  });
}
