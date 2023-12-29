import 'dart:async';
import 'dart:js_interop';
import 'dart:ui';

import 'package:js/js.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:web/web.dart';

/// This class represents the base interface for a barcode reader implementation.
abstract class BarcodeReader {
  const BarcodeReader();

  /// Whether the scanner is currently scanning for barcodes.
  bool get isScanning {
    throw UnimplementedError('isScanning has not been implemented.');
  }

  /// Get the size of the output of the video stream.
  Size get videoSize {
    throw UnimplementedError('videoSize has not been implemented.');
  }

  /// The id for the script tag that loads the barcode library.
  ///
  /// If a script tag with this id already exists,
  /// the library will not be loaded again.
  String get scriptId => 'mobile-scanner-barcode-reader';

  /// The script url for the barcode library.
  String get scriptUrl {
    throw UnimplementedError('scriptUrl has not been implemented.');
  }

  /// Start detecting barcodes.
  ///
  /// The returned stream will emit a [BarcodeCapture] for each detected barcode.
  Stream<BarcodeCapture> detectBarcodes() {
    throw UnimplementedError('detectBarcodes() has not been implemented.');
  }

  /// Check whether the active camera has a flashlight.
  Future<bool> hasTorch() {
    throw UnimplementedError('hasTorch() has not been implemented.');
  }

  /// Load the barcode reader library.
  ///
  /// Does nothing if the library is already loaded.
  Future<void> maybeLoadLibrary() async {
    // Script already exists.
    if (document.querySelector('script#$scriptId') != null) {
      return;
    }

    final Completer<void> completer = Completer();

    final HTMLScriptElement script =
        (document.createElement('script') as HTMLScriptElement)
          ..id = scriptId
          ..async = true
          ..defer = false
          ..type = 'application/javascript'
          ..lang = 'javascript'
          ..crossOrigin = 'anonymous'
          ..src = scriptUrl
          ..onload = allowInterop((JSAny _) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          }).toJS;

    script.onerror = allowInterop((JSAny _) {
      if (!completer.isCompleted) {
        // Remove the script if it did not load.
        document.head!.removeChild(script);

        completer.completeError(
          const MobileScannerException(
            errorCode: MobileScannerErrorCode.genericError,
            errorDetails: MobileScannerErrorDetails(
              message:
                  'Could not load the BarcodeReader script due to a network error.',
            ),
          ),
        );
      }
    }).toJS;

    document.head!.appendChild(script);

    await completer.future;
  }

  /// Set a listener for the media stream settings.
  void setMediaTrackSettingsListener(
    void Function(MediaTrackSettings) listener,
  ) {
    throw UnimplementedError(
      'setMediaTrackConstraintsListener() has not been implemented.',
    );
  }

  /// Set the torch state for the active camera to the given [value].
  Future<void> setTorchState(TorchState value) {
    throw UnimplementedError('setTorchState() has not been implemented.');
  }

  /// Start the barcode reader and initialize the video stream.
  ///
  /// The [options] are used to configure the barcode reader.
  /// The [containerElement] will become the parent of the video output element.
  Future<void> start(
    StartOptions options, {
    required HTMLElement containerElement,
  }) {
    throw UnimplementedError('start() has not been implemented.');
  }

  /// Stop the barcode reader and dispose of the video stream.
  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }
}
