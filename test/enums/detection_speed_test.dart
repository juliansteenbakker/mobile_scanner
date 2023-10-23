import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';

void main() {
  group('$DetectionSpeed tests', () {
    test('can be created from raw value', () {
      const values = <int, DetectionSpeed>{
        0: DetectionSpeed.noDuplicates,
        1: DetectionSpeed.normal,
        2: DetectionSpeed.unrestricted,
      };

      for (final MapEntry<int, DetectionSpeed> entry in values.entries) {
        final DetectionSpeed result = DetectionSpeed.fromRawValue(entry.key);

        expect(result, entry.value);
      }
    });

    test('invalid raw value throws argument error', () {
      const int negative = -1;
      const int outOfRange = 3;

      expect(() => DetectionSpeed.fromRawValue(negative), throwsArgumentError);
      expect(
        () => DetectionSpeed.fromRawValue(outOfRange),
        throwsArgumentError,
      );
    });

    test('can be converted to raw value', () {
      const values = <DetectionSpeed, int>{
        DetectionSpeed.noDuplicates: 0,
        DetectionSpeed.normal: 1,
        DetectionSpeed.unrestricted: 2,
      };

      for (final MapEntry<DetectionSpeed, int> entry in values.entries) {
        final int result = entry.key.rawValue;

        expect(result, entry.value);
      }
    });
  });
}
