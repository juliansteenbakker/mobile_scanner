import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/utils/parse_device_orientation_extension.dart';

void main() {
  group('parseDeviceOrientation', () {
    test('can parse valid device orientation string', () {
      expect(
        'PORTRAIT_UP'.parseDeviceOrientation(),
        DeviceOrientation.portraitUp,
      );
      expect(
        'PORTRAIT_DOWN'.parseDeviceOrientation(),
        DeviceOrientation.portraitDown,
      );
      expect(
        'LANDSCAPE_LEFT'.parseDeviceOrientation(),
        DeviceOrientation.landscapeLeft,
      );
      expect(
        'LANDSCAPE_RIGHT'.parseDeviceOrientation(),
        DeviceOrientation.landscapeRight,
      );
    });

    test(
      'throws ArgumentError when parsing invalid device orientation string',
      () {
        expect(
          () => ''.parseDeviceOrientation(),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'Received an invalid device orientation',
            ),
          ),
        );

        expect(
          () => 'foo'.parseDeviceOrientation(),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'Received an invalid device orientation',
            ),
          ),
        );
      },
    );
  });
}
