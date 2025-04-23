import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_authorization_state.dart';

void main() {
  group('$MobileScannerAuthorizationState tests', () {
    test('can be created from raw value', () {
      const Map<int, MobileScannerAuthorizationState> values = {
        0: MobileScannerAuthorizationState.undetermined,
        1: MobileScannerAuthorizationState.authorized,
        2: MobileScannerAuthorizationState.denied,
      };

      for (final MapEntry<int, MobileScannerAuthorizationState> entry
          in values.entries) {
        final MobileScannerAuthorizationState result =
            MobileScannerAuthorizationState.fromRawValue(entry.key);

        expect(result, entry.value);
      }
    });

    test('invalid raw value throws argument error', () {
      const int negative = -1;
      const int outOfRange = 3;

      expect(
        () => MobileScannerAuthorizationState.fromRawValue(negative),
        throwsArgumentError,
      );
      expect(
        () => MobileScannerAuthorizationState.fromRawValue(outOfRange),
        throwsArgumentError,
      );
    });

    test('can be converted to raw value', () {
      const values = <MobileScannerAuthorizationState, int>{
        MobileScannerAuthorizationState.undetermined: 0,
        MobileScannerAuthorizationState.authorized: 1,
        MobileScannerAuthorizationState.denied: 2,
      };

      for (final MapEntry<MobileScannerAuthorizationState, int> entry
          in values.entries) {
        final int result = entry.key.rawValue;

        expect(result, entry.value);
      }
    });
  });
}
