import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';

void main() {
  group('$CameraFacing tests', () {
    test('can be created from raw value', () {
      const values = <int?, CameraFacing>{
        null: CameraFacing.unknown,
        0: CameraFacing.front,
        1: CameraFacing.back,
        2: CameraFacing.external,
        -1: CameraFacing.unknown,
      };

      for (final MapEntry<int?, CameraFacing> entry in values.entries) {
        final CameraFacing result = CameraFacing.fromRawValue(entry.key);

        expect(result, entry.value);
      }
    });

    test('invalid raw value returns unknown', () {
      const int negative = -10;
      const int outOfRange = 3;

      expect(CameraFacing.fromRawValue(negative), CameraFacing.unknown);
      expect(CameraFacing.fromRawValue(outOfRange), CameraFacing.unknown);
    });

    test('can be converted to raw value', () {
      const values = <CameraFacing, int>{
        CameraFacing.front: 0,
        CameraFacing.back: 1,
        CameraFacing.external: 2,
        CameraFacing.unknown: -1,
      };

      for (final MapEntry<CameraFacing, int> entry in values.entries) {
        final int result = entry.key.rawValue;

        expect(result, entry.value);
      }
    });
  });
}
