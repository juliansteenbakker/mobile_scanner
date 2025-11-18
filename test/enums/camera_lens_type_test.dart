import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_lens_type.dart';

void main() {
  group('$CameraLensType tests', () {
    test('can be created from raw value', () {
      const values = <int?, CameraLensType>{
        null: CameraLensType.any,
        0: CameraLensType.normal,
        1: CameraLensType.wide,
        2: CameraLensType.zoom,
        -1: CameraLensType.any,
      };

      for (final entry in values.entries) {
        final result = CameraLensType.fromRawValue(entry.key);

        expect(result, entry.value);
      }
    });

    test('invalid raw value returns any', () {
      const negative = -10;
      const outOfRange = 3;

      expect(CameraLensType.fromRawValue(negative), CameraLensType.any);
      expect(CameraLensType.fromRawValue(outOfRange), CameraLensType.any);
    });

    test('can be converted to raw value', () {
      const values = <CameraLensType, int>{
        CameraLensType.normal: 0,
        CameraLensType.wide: 1,
        CameraLensType.zoom: 2,
        CameraLensType.any: -1,
      };

      for (final entry in values.entries) {
        final result = entry.key.rawValue;

        expect(result, entry.value);
      }
    });

    test('all enum values have unique raw values', () {
      final rawValues = CameraLensType.values.map((e) => e.rawValue).toList();
      final uniqueValues = rawValues.toSet();

      expect(
        rawValues.length,
        uniqueValues.length,
        reason: 'All CameraLensType values should have unique raw values',
      );
    });

    test('roundtrip conversion preserves value', () {
      for (final lensType in CameraLensType.values) {
        final rawValue = lensType.rawValue;
        final converted = CameraLensType.fromRawValue(rawValue);

        expect(converted, lensType);
      }
    });
  });
}
