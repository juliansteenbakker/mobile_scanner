import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_state.dart';

void main() {
  group('$MobileScannerState tests', () {
    test('can be created from raw value', () {
      const values = {
        0: MobileScannerState.undetermined,
        1: MobileScannerState.authorized,
        2: MobileScannerState.denied,
      };

      for (final MapEntry<int, MobileScannerState> entry in values.entries) {
        final MobileScannerState result = MobileScannerState.fromRawValue(
          entry.key,
        );

        expect(result, entry.value);
      }
    });

    test('invalid raw value throws argument error', () {
      const int negative = -1;
      const int outOfRange = 3;

      expect(
        () => MobileScannerState.fromRawValue(negative),
        throwsArgumentError,
      );
      expect(
        () => MobileScannerState.fromRawValue(outOfRange),
        throwsArgumentError,
      );
    });

    test('can be converted to raw value', () {
      const values = <MobileScannerState, int>{
        MobileScannerState.undetermined: 0,
        MobileScannerState.authorized: 1,
        MobileScannerState.denied: 2,
      };

      for (final MapEntry<MobileScannerState, int> entry in values.entries) {
        final int result = entry.key.rawValue;

        expect(result, entry.value);
      }
    });
  });
}
