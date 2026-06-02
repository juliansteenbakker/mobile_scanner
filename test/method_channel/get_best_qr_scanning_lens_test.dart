import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getBestQrScanningLens', () {
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
                MethodChannelMobileScanner.kGetBestQrScanningLensMethodName) {
              return 0;
            }
            return null;
          });

      final result = await platform.getBestQrScanningLens();

      expect(result, CameraLensType.normal);
    });

    test('returns wide lens for raw value 1', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetBestQrScanningLensMethodName) {
              return 1;
            }
            return null;
          });

      final result = await platform.getBestQrScanningLens();

      expect(result, CameraLensType.wide);
    });

    test('returns zoom lens for raw value 2', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetBestQrScanningLensMethodName) {
              return 2;
            }
            return null;
          });

      final result = await platform.getBestQrScanningLens();

      expect(result, CameraLensType.zoom);
    });

    test('returns normal lens when platform returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetBestQrScanningLensMethodName) {
              return null;
            }
            return null;
          });

      final result = await platform.getBestQrScanningLens();

      expect(result, CameraLensType.normal);
    });

    test('passes facing back (rawValue 1) to platform channel', () async {
      MethodCall? capturedCall;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetBestQrScanningLensMethodName) {
              capturedCall = methodCall;
              return 0;
            }
            return null;
          });

      await platform.getBestQrScanningLens();

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
                MethodChannelMobileScanner.kGetBestQrScanningLensMethodName) {
              capturedCall = methodCall;
              return 0;
            }
            return null;
          });

      await platform.getBestQrScanningLens(facing: CameraFacing.front);

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
                MethodChannelMobileScanner.kGetBestQrScanningLensMethodName) {
              return 0;
            }
            return null;
          });

      await platform.getBestQrScanningLens();

      expect(methodCalls, hasLength(1));
      expect(
        methodCalls.first.method,
        MethodChannelMobileScanner.kGetBestQrScanningLensMethodName,
      );
    });
  });
}
