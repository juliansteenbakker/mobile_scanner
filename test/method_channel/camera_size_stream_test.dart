import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('camera size events reach the camera size stream', () async {
    final platform = MethodChannelMobileScanner();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockStreamHandler(
            platform.eventChannel,
            MockStreamHandler.inline(
              onListen:
                  (_, events) => events.success(<String, Object?>{
                    'name': MethodChannelMobileScanner.kCameraSizeEventName,
                    'data': <String, Object?>{
                      'width': 1920.0,
                      'height': 1080.0,
                    },
                  }),
            ),
          );
    addTearDown(
      () => messenger.setMockStreamHandler(platform.eventChannel, null),
    );

    await expectLater(platform.cameraSizeStream, emits(const Size(1920, 1080)));
  });
}
