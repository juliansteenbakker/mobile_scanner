import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getSupportedLenses() tests', () {
    late MethodChannelMobileScanner platform;
    late List<MethodCall> methodCalls;

    setUp(() {
      platform = MethodChannelMobileScanner();
      MobileScannerPlatform.instance = platform;
      methodCalls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          switch (methodCall.method) {
            case 'getSupportedLenses':
              // Return mock lens types based on test cases
              return null; // Will be overridden in specific tests
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, null);
    });

    test('returns list of supported lenses', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          if (methodCall.method == 'getSupportedLenses') {
            return [0, 1, 2]; // normal, wide, zoom
          }
          return null;
        },
      );

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(3));
      expect(lenses, contains(CameraLensType.normal));
      expect(lenses, contains(CameraLensType.wide));
      expect(lenses, contains(CameraLensType.zoom));
    });

    test('returns normal lens only', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          if (methodCall.method == 'getSupportedLenses') {
            return [0]; // normal only
          }
          return null;
        },
      );

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(1));
      expect(lenses.first, CameraLensType.normal);
    });

    test('returns wide lens only', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          if (methodCall.method == 'getSupportedLenses') {
            return [1]; // wide only
          }
          return null;
        },
      );

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(1));
      expect(lenses.first, CameraLensType.wide);
    });

    test('returns zoom lens only', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          if (methodCall.method == 'getSupportedLenses') {
            return [2]; // zoom only
          }
          return null;
        },
      );

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(1));
      expect(lenses.first, CameraLensType.zoom);
    });

    test('returns "any" when platform returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          if (methodCall.method == 'getSupportedLenses') {
            return null;
          }
          return null;
        },
      );

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(1));
      expect(lenses.first, CameraLensType.any);
    });

    test('returns "any" when platform returns empty list', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          if (methodCall.method == 'getSupportedLenses') {
            return [];
          }
          return null;
        },
      );

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(1));
      expect(lenses.first, CameraLensType.any);
    });

    test('filters out invalid raw values', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          if (methodCall.method == 'getSupportedLenses') {
            return [0, 'invalid', 1, null, 2]; // Mixed valid and invalid
          }
          return null;
        },
      );

      final lenses = await platform.getSupportedLenses();

      // Should only contain valid lens types (0, 1, 2)
      expect(lenses, hasLength(3));
      expect(lenses, contains(CameraLensType.normal));
      expect(lenses, contains(CameraLensType.wide));
      expect(lenses, contains(CameraLensType.zoom));
    });

    test('returns "any" when all values are invalid', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          if (methodCall.method == 'getSupportedLenses') {
            return ['invalid', null, 'another-invalid']; // All invalid
          }
          return null;
        },
      );

      final lenses = await platform.getSupportedLenses();

      // Should return 'any' when all values are filtered out
      expect(lenses, hasLength(1));
      expect(lenses.first, CameraLensType.any);
    });

    test('handles platform returning -1 (any)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          if (methodCall.method == 'getSupportedLenses') {
            return [-1]; // any
          }
          return null;
        },
      );

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(1));
      expect(lenses.first, CameraLensType.any);
    });

    test('calls correct method on platform channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          if (methodCall.method == 'getSupportedLenses') {
            return [0];
          }
          return null;
        },
      );

      await platform.getSupportedLenses();

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'getSupportedLenses');
    });

    test('returns normal and zoom lenses (common dual camera setup)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          if (methodCall.method == 'getSupportedLenses') {
            return [0, 2]; // normal and zoom
          }
          return null;
        },
      );

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(2));
      expect(lenses, contains(CameraLensType.normal));
      expect(lenses, contains(CameraLensType.zoom));
      expect(lenses, isNot(contains(CameraLensType.wide)));
    });

    test('returns normal, wide, and zoom (common triple camera setup)',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          if (methodCall.method == 'getSupportedLenses') {
            return [0, 1, 2]; // normal, wide, zoom
          }
          return null;
        },
      );

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(3));
      expect(lenses, contains(CameraLensType.normal));
      expect(lenses, contains(CameraLensType.wide));
      expect(lenses, contains(CameraLensType.zoom));
    });
  });
}
