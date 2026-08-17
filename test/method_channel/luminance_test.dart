import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelMobileScanner platform;

  setUp(() {
    platform = MethodChannelMobileScanner();
    MobileScannerPlatform.instance = platform;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.methodChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(platform.eventChannel, null);
  });

  group('setLuminanceEnabled', () {
    test(
      'invokes the correct method with the enabled flag as argument',
      () async {
        MethodCall? capturedCall;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(platform.methodChannel, (
              methodCall,
            ) async {
              capturedCall = methodCall;
              return null;
            });

        await platform.setLuminanceEnabled(enabled: true);

        expect(capturedCall, isNotNull);
        expect(
          capturedCall!.method,
          MethodChannelMobileScanner.kSetLuminanceEnabledMethodName,
        );
        expect(capturedCall!.arguments, isTrue);
      },
    );

    test('passes false through unchanged', () async {
      MethodCall? capturedCall;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            methodCall,
          ) async {
            capturedCall = methodCall;
            return null;
          });

      await platform.setLuminanceEnabled(enabled: false);

      expect(capturedCall!.arguments, isFalse);
    });
  });

  group('luminanceStream', () {
    void mockEventChannel(List<Map<String, Object?>> events) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            platform.eventChannel,
            MockStreamHandler.inline(
              onListen: (Object? arguments, MockStreamHandlerEventSink sink) {
                events.forEach(sink.success);
              },
            ),
          );
    }

    test('emits only luminance-named events, parsed as a double', () async {
      mockEventChannel([
        {'name': 'barcode', 'data': 'ignored'},
        {'name': 'luminance', 'data': 12.5},
        {'name': 'torchState', 'data': 1},
        {'name': 'luminance', 'data': 200},
      ]);

      final samples = await platform.luminanceStream.take(2).toList();

      // The second luminance event is an int (`200`, as native platforms may
      // send a whole-number luminance); it must still parse as a double.
      expect(samples, [12.5, 200.0]);
    });

    test('defaults a malformed sample to 255.0 (bright), never dark', () async {
      mockEventChannel([
        {'name': 'luminance', 'data': null},
      ]);

      final sample = await platform.luminanceStream.first;

      expect(sample, 255.0);
    });
  });
}
