import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getSupportedLenses', () {
    late MethodChannelMobileScanner platform;

    setUp(() {
      platform = MethodChannelMobileScanner();
      MobileScannerPlatform.instance = platform;
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, null);
    });

    test('returns set of supported lenses', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return [
                CameraLensType.normal.rawValue,
                CameraLensType.wide.rawValue,
                CameraLensType.zoom.rawValue,
              ];
            }
            return null;
          });

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(3));
      expect(lenses, contains(CameraLensType.normal));
      expect(lenses, contains(CameraLensType.wide));
      expect(lenses, contains(CameraLensType.zoom));
    });

    test('returns normal lens only', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return [CameraLensType.normal.rawValue];
            }
            return null;
          });

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(1));
      expect(lenses, contains(CameraLensType.normal));
    });

    test('returns wide lens only', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return [CameraLensType.wide.rawValue];
            }
            return null;
          });

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(1));
      expect(lenses, contains(CameraLensType.wide));
    });

    test('returns zoom lens only', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return [CameraLensType.zoom.rawValue];
            }
            return null;
          });

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(1));
      expect(lenses, contains(CameraLensType.zoom));
    });

    test('returns empty set when platform returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return null;
            }
            return null;
          });

      final lenses = await platform.getSupportedLenses();

      expect(lenses, isEmpty);
    });

    test('returns empty set when platform returns empty list', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return <int>[];
            }
            return null;
          });

      final lenses = await platform.getSupportedLenses();

      expect(lenses, isEmpty);
    });

    test('filters out non-integer values', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return [
                CameraLensType.normal.rawValue,
                'invalid',
                CameraLensType.wide.rawValue,
                null,
                CameraLensType.zoom.rawValue,
              ];
            }
            return null;
          });

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(3));
      expect(lenses, contains(CameraLensType.normal));
      expect(lenses, contains(CameraLensType.wide));
      expect(lenses, contains(CameraLensType.zoom));
    });

    test('returns empty set when all values are non-integers', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return ['invalid', null, 'another-invalid'];
            }
            return null;
          });

      final lenses = await platform.getSupportedLenses();

      expect(lenses, isEmpty);
    });

    test('handles platform returning -1 (maps to any)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return [CameraLensType.any.rawValue];
            }
            return null;
          });

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(1));
      expect(lenses, contains(CameraLensType.any));
    });

    test('handles unknown positive integer values (maps to any)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return [99];
            }
            return null;
          });

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(1));
      expect(lenses, contains(CameraLensType.any));
    });

    test('handles unknown negative integer values (maps to any)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return [-99];
            }
            return null;
          });

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(1));
      expect(lenses, contains(CameraLensType.any));
    });

    test(
      'maps unknown values to any lens type while keeping valid ones',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(platform.methodChannel, (
              methodCall,
            ) async {
              if (methodCall.method ==
                  MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
                return [
                  CameraLensType.normal.rawValue,
                  -99,
                  CameraLensType.wide.rawValue,
                ];
              }
              return null;
            });

        final lenses = await platform.getSupportedLenses();

        expect(lenses, hasLength(3));
        expect(lenses, contains(CameraLensType.normal));
        expect(lenses, contains(CameraLensType.any));
        expect(lenses, contains(CameraLensType.wide));
      },
    );

    test('calls correct method on platform channel', () async {
      final methodCalls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            methodCalls.add(methodCall);

            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return [CameraLensType.normal.rawValue];
            }
            return null;
          });

      await platform.getSupportedLenses();

      expect(methodCalls, hasLength(1));
      expect(
        methodCalls.first.method,
        MethodChannelMobileScanner.kGetSupportedLensesMethodName,
      );
    });

    test('returns normal and zoom lenses (common dual camera setup)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return [
                CameraLensType.normal.rawValue,
                CameraLensType.zoom.rawValue,
              ];
            }
            return null;
          });

      final lenses = await platform.getSupportedLenses();

      expect(lenses, hasLength(2));
      expect(lenses, contains(CameraLensType.normal));
      expect(lenses, contains(CameraLensType.zoom));
      expect(lenses, isNot(contains(CameraLensType.wide)));
    });

    test(
      'returns normal, wide, and zoom (common triple camera setup)',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(platform.methodChannel, (
              methodCall,
            ) async {
              if (methodCall.method ==
                  MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
                return [
                  CameraLensType.normal.rawValue,
                  CameraLensType.wide.rawValue,
                  CameraLensType.zoom.rawValue,
                ];
              }
              return null;
            });

        final lenses = await platform.getSupportedLenses();

        expect(lenses, hasLength(3));
        expect(lenses, contains(CameraLensType.normal));
        expect(lenses, contains(CameraLensType.wide));
        expect(lenses, contains(CameraLensType.zoom));
      },
    );

    test(
      'deduplicates multiple unknown values to single any lens type',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(platform.methodChannel, (
              methodCall,
            ) async {
              if (methodCall.method ==
                  MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
                return [
                  CameraLensType.normal.rawValue,
                  -99,
                  CameraLensType.wide.rawValue,
                  -10,
                  99,
                ];
              }
              return null;
            });

        final lenses = await platform.getSupportedLenses();

        expect(lenses, hasLength(3));
        expect(lenses, contains(CameraLensType.normal));
        expect(lenses, contains(CameraLensType.wide));
        expect(lenses, contains(CameraLensType.any));
      },
    );
  });

  group('getSupportedLenses with facing filter', () {
    late MethodChannelMobileScanner platform;

    setUp(() {
      platform = MethodChannelMobileScanner();
      MobileScannerPlatform.instance = platform;
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, null);
    });

    test('passes facing back (rawValue 1) to platform channel', () async {
      MethodCall? capturedCall;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              capturedCall = methodCall;
              return [CameraLensType.normal.rawValue];
            }
            return null;
          });

      await platform.getSupportedLenses(facing: CameraFacing.back);

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
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              capturedCall = methodCall;
              return [CameraLensType.normal.rawValue];
            }
            return null;
          });

      await platform.getSupportedLenses(facing: CameraFacing.front);

      expect(capturedCall, isNotNull);
      expect(capturedCall!.arguments, equals({'facing': 0}));
    });

    test('passes null args when no facing provided', () async {
      MethodCall? capturedCall;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              capturedCall = methodCall;
              return [CameraLensType.normal.rawValue];
            }
            return null;
          });

      await platform.getSupportedLenses();

      expect(capturedCall, isNotNull);
      expect(capturedCall!.arguments, isNull);
    });

    test('returns only back-camera lenses when back facing passed', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              final args = methodCall.arguments as Map?;
              if (args?['facing'] == 1) {
                return [
                  CameraLensType.normal.rawValue,
                  CameraLensType.zoom.rawValue,
                ];
              }
              return [CameraLensType.normal.rawValue];
            }
            return null;
          });

      final backLenses = await platform.getSupportedLenses(
        facing: CameraFacing.back,
      );

      expect(backLenses, hasLength(2));
      expect(backLenses, contains(CameraLensType.normal));
      expect(backLenses, contains(CameraLensType.zoom));
      expect(backLenses, isNot(contains(CameraLensType.wide)));
    });

    test('returns only front-camera lenses when front facing passed', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              final args = methodCall.arguments as Map?;
              if (args?['facing'] == 0) {
                return [CameraLensType.normal.rawValue];
              }
              return [
                CameraLensType.normal.rawValue,
                CameraLensType.zoom.rawValue,
              ];
            }
            return null;
          });

      final frontLenses = await platform.getSupportedLenses(
        facing: CameraFacing.front,
      );

      expect(frontLenses, hasLength(1));
      expect(frontLenses, contains(CameraLensType.normal));
      expect(frontLenses, isNot(contains(CameraLensType.zoom)));
      expect(frontLenses, isNot(contains(CameraLensType.wide)));
    });

    test('deduplicates results', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            if (methodCall.method ==
                MethodChannelMobileScanner.kGetSupportedLensesMethodName) {
              return [
                CameraLensType.normal.rawValue,
                CameraLensType.normal.rawValue,
                CameraLensType.zoom.rawValue,
              ];
            }
            return null;
          });

      final lenses = await platform.getSupportedLenses(
        facing: CameraFacing.back,
      );

      expect(lenses, hasLength(2));
      expect(lenses, contains(CameraLensType.normal));
      expect(lenses, contains(CameraLensType.zoom));
    });
  });
}
