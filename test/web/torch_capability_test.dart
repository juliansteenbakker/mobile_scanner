@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/web/media_track_extension.dart';
import 'package:web/web.dart';

void main() {
  // Regression for https://github.com/juliansteenbakker/mobile_scanner/issues/1796.
  // Same approach as flutter/packages camera_web 956ba9e: a boolean must be
  // readable, and a sequence is enabled only when it contains true.
  group('readTorchCapability', () {
    test('is true for a boolean true', () {
      expect(readTorchCapability(true.toJS), isTrue);
      expect(capabilitiesWithTorch(true.toJS).canEnableTorch, isTrue);
    });

    test('is false for a boolean false', () {
      expect(readTorchCapability(false.toJS), isFalse);
      expect(capabilitiesWithTorch(false.toJS).canEnableTorch, isFalse);
    });

    test('is true when an array contains true', () {
      final withTrue = <JSBoolean>[false.toJS, true.toJS].toJS;
      final onlyTrue = <JSBoolean>[true.toJS].toJS;

      expect(readTorchCapability(withTrue), isTrue);
      expect(readTorchCapability(onlyTrue), isTrue);
      expect(capabilitiesWithTorch(withTrue).canEnableTorch, isTrue);
      expect(capabilitiesWithTorch(onlyTrue).canEnableTorch, isTrue);
    });

    test('is false when an array does not contain true', () {
      final onlyFalse = <JSBoolean>[false.toJS].toJS;
      final empty = <JSBoolean>[].toJS;

      expect(readTorchCapability(onlyFalse), isFalse);
      expect(readTorchCapability(empty), isFalse);
      expect(capabilitiesWithTorch(onlyFalse).canEnableTorch, isFalse);
      expect(capabilitiesWithTorch(empty).canEnableTorch, isFalse);
    });

    test('is false for null', () {
      expect(readTorchCapability(null), isFalse);

      final object = JSObject()..setProperty('torch'.toJS, null);
      final capabilities = object as MediaTrackCapabilities;

      expect(readTorchCapability(capabilities.torchNullable), isFalse);
      expect(capabilities.canEnableTorch, isFalse);
    });

    test('throws for an unrecognized shape', () {
      final notBooleans = <JSString>['on'.toJS].toJS;

      expect(
        () => readTorchCapability('on'.toJS),
        throwsA(isA<MobileScannerException>()),
      );
      expect(
        () => readTorchCapability(notBooleans),
        throwsA(isA<MobileScannerException>()),
      );
      expect(
        () => capabilitiesWithTorch(notBooleans).canEnableTorch,
        throwsA(isA<MobileScannerException>()),
      );
    });

    test('is false for undefined', () {
      // An omitted property is JavaScript undefined.
      final capabilities = JSObject() as MediaTrackCapabilities;

      expect(readTorchCapability(capabilities.torchNullable), isFalse);
      expect(capabilities.canEnableTorch, isFalse);
    });
  });
}

/// Builds a [MediaTrackCapabilities] whose `torch` property is [torch].
///
/// `package:web` types that property as `sequence<boolean>`, which cannot
/// represent the bare boolean Chromium and WebKit report.
MediaTrackCapabilities capabilitiesWithTorch(JSAny torch) {
  final capabilities = JSObject()..setProperty('torch'.toJS, torch);

  return capabilities as MediaTrackCapabilities;
}
