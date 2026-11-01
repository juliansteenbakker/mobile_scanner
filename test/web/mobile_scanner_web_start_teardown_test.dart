@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/web_barcode_reader.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/web/mobile_scanner_web.dart';
import 'package:web/web.dart' as web;

import 'utils/media_stream_test_utils.dart';

void main() {
  late GetUserMediaStub getUserMedia;
  FailingBarcodeDetectorStub? failingBarcodeDetector;

  setUp(() {
    web.window.localStorage.clear();
    getUserMedia = GetUserMediaStub();
  });

  tearDown(() {
    getUserMedia.restore();
    failingBarcodeDetector?.restore();
    failingBarcodeDetector = null;
  });

  group('MobileScannerWeb teardown during start', () {
    test('dispose() while acquiring the camera releases the stream', () async {
      final plugin =
          MobileScannerWeb()
            ..setWebBarcodeReader(WebBarcodeReader.barcodeDetector);

      final startFuture = plugin.start(testStartOptions);

      await getUserMedia.awaitCall();

      // The scanner is dismissed while getUserMedia is still pending.
      await plugin.dispose();

      final stream = getUserMedia.resolve();

      await expectLater(
        startFuture,
        throwsA(isA<MobileScannerException>()),
        reason: 'a start that was torn down must not report a running camera',
      );

      expect(
        allEnded(stream),
        isTrue,
        reason: 'the camera acquired by the aborted start must be released',
      );
    });

    test('stop() before acquiring the camera never requests it', () async {
      final plugin =
          MobileScannerWeb()
            ..setWebBarcodeReader(WebBarcodeReader.barcodeDetector);

      // Resolve up front, so that a start that does reach getUserMedia fails
      // on the assertion below rather than hanging on the stub.
      getUserMedia.resolve();

      // start() is parked on loading the reader's library when this lands.
      final startFuture = plugin.start(testStartOptions);

      // Listen before stopping: the start fails while stop() is still being
      // awaited, and an unobserved failure would be reported as uncaught.
      final startFailure = expectLater(
        startFuture,
        throwsA(isA<MobileScannerException>()),
        reason: 'a start that was stopped must not report a running camera',
      );

      await plugin.stop();
      await startFailure;

      expect(
        getUserMedia.callCount,
        0,
        reason: 'a stopped scanner must not prompt for or light the camera',
      );
    });

    test('stop() while acquiring the camera releases the stream', () async {
      final plugin =
          MobileScannerWeb()
            ..setWebBarcodeReader(WebBarcodeReader.barcodeDetector);

      final startFuture = plugin.start(testStartOptions);

      await getUserMedia.awaitCall();

      // The scanner is stopped while getUserMedia is still pending.
      await plugin.stop();

      final stream = getUserMedia.resolve();

      await expectLater(
        startFuture,
        throwsA(isA<MobileScannerException>()),
        reason: 'a start that was stopped must not report a running camera',
      );

      expect(
        allEnded(stream),
        isTrue,
        reason: 'the camera acquired by the stopped start must be released',
      );
    });
  });

  group('MobileScannerWeb restart after teardown', () {
    test('stop() while selecting the reader allows a new start', () async {
      final plugin =
          MobileScannerWeb()..setWebBarcodeReader(WebBarcodeReader.auto);
      addTearDown(plugin.stop);

      getUserMedia.resolve();

      // In auto mode, start() is parked on the BarcodeDetector support check,
      // before it has assigned its reader, when this lands.
      final startFailure = expectLater(
        plugin.start(testStartOptions),
        throwsA(isA<MobileScannerException>()),
        reason: 'a start that was stopped must not report a running camera',
      );

      await plugin.stop();
      await startFailure;

      final restartError = await plugin
          .start(testStartOptions)
          .then<Object?>((_) => null, onError: (Object error) => error);

      expect(
        restartError,
        isNot(
          isA<MobileScannerException>().having(
            (e) => e.errorCode,
            'errorCode',
            MobileScannerErrorCode.controllerAlreadyInitialized,
          ),
        ),
        reason: 'the aborted start must not leave its reader behind',
      );
    });
  });

  group('MobileScannerWeb start failure', () {
    test('a start that fails after acquiring the camera releases it', () async {
      failingBarcodeDetector = FailingBarcodeDetectorStub();

      final plugin =
          MobileScannerWeb()
            ..setWebBarcodeReader(WebBarcodeReader.barcodeDetector);

      final startFuture = plugin.start(testStartOptions);

      await getUserMedia.awaitCall();

      final stream = getUserMedia.resolve();

      await expectLater(
        startFuture,
        throwsA(isA<MobileScannerException>()),
        reason: 'the failing BarcodeDetector must fail the start',
      );

      expect(
        allEnded(stream),
        isTrue,
        reason: 'a failed start must not leave the camera running',
      );
    });
  });
}
