import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/web/web_library_versions.dart';

void main() {
  test('pinned web library versions match package.json', () {
    // The package.json at the repository root mirrors the pinned versions,
    // so that Dependabot can detect and propose updates. When Dependabot
    // bumps package.json, this test fails until the Dart constants in
    // lib/src/web/web_library_versions.dart are updated to match.
    final packageJson =
        jsonDecode(File('package.json').readAsStringSync())
            as Map<String, dynamic>;
    final dependencies = packageJson['dependencies'] as Map<String, dynamic>;

    expect(
      dependencies['@zxing/library'],
      zxingJsVersion,
      reason:
          'package.json pins @zxing/library to a different version than '
          'zxingJsVersion in lib/src/web/web_library_versions.dart. '
          'If Dependabot updated package.json, update the Dart constant '
          'to match.',
    );
    expect(
      dependencies['zxing-wasm'],
      zxingWasmVersion,
      reason:
          'package.json pins zxing-wasm to a different version than '
          'zxingWasmVersion in lib/src/web/web_library_versions.dart. '
          'If Dependabot updated package.json, update the Dart constant '
          'to match. When crossing a major version, also verify the format '
          'names in zxing_wasm_formats.dart against the release notes.',
    );
  });

  test('pinned versions are exact (no version range operators)', () {
    const rangeOperators = ['^', '~', '>', '<', '*', 'x'];

    for (final version in [zxingJsVersion, zxingWasmVersion]) {
      for (final operator in rangeOperators) {
        expect(
          version.contains(operator),
          isFalse,
          reason: 'Version "$version" must be an exact pin',
        );
      }
    }
  });
}
