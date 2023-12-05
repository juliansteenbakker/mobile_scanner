import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';

void main() {
  group('$CameraFacing tests', () {
    test('can be created from raw value', () {
      const values = <int, CameraFacing>{
        0: CameraFacing.front,
        1: CameraFacing.back,
      };

      for (final MapEntry<int, CameraFacing> entry in values.entries) {
        final CameraFacing result = CameraFacing.fromRawValue(entry.key);

        expect(result, entry.value);
      }
    });

    test('invalid raw value throws argument error', () {
      const int negative = -1;
      const int outOfRange = 2;

      expect(() => CameraFacing.fromRawValue(negative), throwsArgumentError);
      expect(() => CameraFacing.fromRawValue(outOfRange), throwsArgumentError);
    });

    test('can be converted to raw value', () {
      const values = <CameraFacing, int>{
        CameraFacing.front: 0,
        CameraFacing.back: 1,
      };

      for (final MapEntry<CameraFacing, int> entry in values.entries) {
        final int result = entry.key.rawValue;

        expect(result, entry.value);
      }
    });
  });
}
