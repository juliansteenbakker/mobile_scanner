import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';

void main() {
  group('$MobileScannerException tests', () {
    group('constructor', () {
      test('creates instance with only errorCode', () {
        const exception = MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        );

        expect(exception.errorCode, MobileScannerErrorCode.permissionDenied);
        expect(exception.errorDetails, isNull);
      });

      test('creates instance with errorCode and errorDetails', () {
        const exception = MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
          errorDetails: MobileScannerErrorDetails(
            code: 'CAMERA_ERROR',
            details: {'reason': 'Hardware failure'},
            message: 'Camera failed to initialize',
          ),
        );

        expect(exception.errorCode, MobileScannerErrorCode.genericError);
        expect(exception.errorDetails, isNotNull);
        expect(exception.errorDetails?.code, 'CAMERA_ERROR');
        expect(exception.errorDetails?.details, {'reason': 'Hardware failure'});
        expect(exception.errorDetails?.message, 'Camera failed to initialize');
      });
    });

    group('toString', () {
      test('returns string with errorCode name when no errorDetails', () {
        const exception = MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        );

        expect(
          exception.toString(),
          'MobileScannerException(permissionDenied)',
        );
      });

      test('returns string when errorDetails is explicitly null', () {
        const exception = MobileScannerException(
          errorCode: MobileScannerErrorCode.controllerAlreadyInitialized,
        );

        expect(
          exception.toString(),
          'MobileScannerException(controllerAlreadyInitialized)',
        );
      });

      test(
        'returns string with errorCode and message when errorDetails present',
        () {
          const exception = MobileScannerException(
            errorCode: MobileScannerErrorCode.genericError,
            errorDetails: MobileScannerErrorDetails(
              message: 'Something went wrong',
            ),
          );

          expect(
            exception.toString(),
            'MobileScannerException(genericError, Something went wrong)',
          );
        },
      );

      test(
        'returns string without message when errorDetails has no message',
        () {
          const exception = MobileScannerException(
            errorCode: MobileScannerErrorCode.genericError,
            errorDetails: MobileScannerErrorDetails(code: 'ERROR_CODE'),
          );

          expect(exception.toString(), 'MobileScannerException(genericError)');
        },
      );

      test('works with all error codes', () {
        for (final errorCode in MobileScannerErrorCode.values) {
          final exception = MobileScannerException(errorCode: errorCode);

          expect(
            exception.toString(),
            'MobileScannerException(${errorCode.name})',
          );
        }
      });
    });
  });

  group('$MobileScannerErrorDetails tests', () {
    group('constructor', () {
      test('creates instance with default null values', () {
        const details = MobileScannerErrorDetails();

        expect(details.code, isNull);
        expect(details.details, isNull);
        expect(details.message, isNull);
      });

      test('creates instance with all values provided', () {
        const details = MobileScannerErrorDetails(
          code: 'PERMISSION_DENIED',
          details: {'platform': 'iOS', 'version': '17.0'},
          message: 'Camera permission was denied by user',
        );

        expect(details.code, 'PERMISSION_DENIED');
        expect(details.details, {'platform': 'iOS', 'version': '17.0'});
        expect(details.message, 'Camera permission was denied by user');
      });

      test('creates instance with only code', () {
        const details = MobileScannerErrorDetails(code: 'UNKNOWN_ERROR');

        expect(details.code, 'UNKNOWN_ERROR');
        expect(details.details, isNull);
        expect(details.message, isNull);
      });

      test('creates instance with only message', () {
        const details = MobileScannerErrorDetails(message: 'Error occurred');

        expect(details.code, isNull);
        expect(details.details, isNull);
        expect(details.message, 'Error occurred');
      });

      test('creates instance with only details', () {
        const details = MobileScannerErrorDetails(
          details: {'errorType': 'hardware'},
        );

        expect(details.code, isNull);
        expect(details.details, {'errorType': 'hardware'});
        expect(details.message, isNull);
      });

      test('creates instance with complex details object', () {
        const details = MobileScannerErrorDetails(
          details: {
            'nested': {'key': 'value'},
            'list': [1, 2, 3],
            'boolean': true,
          },
        );

        expect(details.details, {
          'nested': {'key': 'value'},
          'list': [1, 2, 3],
          'boolean': true,
        });
      });

      test('creates instance with empty string values', () {
        const details = MobileScannerErrorDetails(code: '', message: '');

        expect(details.code, '');
        expect(details.message, '');
      });
    });
  });

  group('$MobileScannerBarcodeException tests', () {
    group('constructor', () {
      test('creates instance with message', () {
        const exception = MobileScannerBarcodeException('Barcode not found');

        expect(exception.message, 'Barcode not found');
      });

      test('creates instance with null message', () {
        const exception = MobileScannerBarcodeException(null);

        expect(exception.message, isNull);
      });

      test('creates instance with empty message', () {
        const exception = MobileScannerBarcodeException('');

        expect(exception.message, '');
      });
    });

    group('toString', () {
      test('returns string with message when message is non-empty', () {
        const exception = MobileScannerBarcodeException(
          'Failed to decode barcode',
        );

        expect(
          exception.toString(),
          'MobileScannerBarcodeException(Failed to decode barcode)',
        );
      });

      test('returns default message when message is null', () {
        const exception = MobileScannerBarcodeException(null);

        expect(
          exception.toString(),
          'MobileScannerBarcodeException(Could not detect a barcode in the '
          'input image.)',
        );
      });

      test('returns default message when message is empty', () {
        const exception = MobileScannerBarcodeException('');

        expect(
          exception.toString(),
          'MobileScannerBarcodeException(Could not detect a barcode in the '
          'input image.)',
        );
      });

      test('returns string with whitespace-only message', () {
        const exception = MobileScannerBarcodeException('   ');

        expect(
          exception.toString(),
          'MobileScannerBarcodeException(   )',
        );
      });
    });
  });
}
