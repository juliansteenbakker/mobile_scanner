import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';

void main() {
  group('$TorchState tests', () {
    test('can be created from raw value', () {
      const values = <int, TorchState>{
        0: TorchState.off,
        1: TorchState.on,
        2: TorchState.auto,
        -1: TorchState.unavailable,
      };

      for (final MapEntry<int, TorchState> entry in values.entries) {
        final TorchState result = TorchState.fromRawValue(entry.key);

        expect(result, entry.value);
      }
    });

    test('invalid raw value throws argument error', () {
      const int negative = -2;
      const int outOfRange = 3;

      expect(() => TorchState.fromRawValue(negative), throwsArgumentError);
      expect(() => TorchState.fromRawValue(outOfRange), throwsArgumentError);
    });

    test('can be converted to raw value', () {
      const values = <TorchState, int>{
        TorchState.unavailable: -1,
        TorchState.off: 0,
        TorchState.on: 1,
        TorchState.auto: 2,
      };

      for (final MapEntry<TorchState, int> entry in values.entries) {
        final int result = entry.key.rawValue;

        expect(result, entry.value);
      }
    });
  });
}
