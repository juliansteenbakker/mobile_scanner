import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';

void main() {
  group('$MobileScannerException tests', () {
    test('can be constructed with error code only', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );

      expect(exception.errorCode, MobileScannerErrorCode.genericError);
      expect(exception.errorDetails, isNull);
    });

    test('can be constructed with error code and error details', () {
      const errorDetails = MobileScannerErrorDetails(
        code: 'TEST_ERROR',
        message: 'Test error message',
        details: 'Additional details',
      );
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
        errorDetails: errorDetails,
      );

      expect(exception.errorCode, MobileScannerErrorCode.permissionDenied);
      expect(exception.errorDetails, errorDetails);
      expect(exception.errorDetails?.code, 'TEST_ERROR');
      expect(exception.errorDetails?.message, 'Test error message');
      expect(exception.errorDetails?.details, 'Additional details');
    });

    test('implements Exception interface', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );

      expect(exception, isA<Exception>());
    });

    test('toString returns formatted string without error details', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );

      expect(exception.toString(), 'MobileScannerException(permissionDenied)');
    });

    test(
      'toString returns formatted string with error details but no message',
      () {
        const errorDetails = MobileScannerErrorDetails(
          code: 'TEST_ERROR',
          details: 'Some details',
        );
        const exception = MobileScannerException(
          errorCode: MobileScannerErrorCode.unsupported,
          errorDetails: errorDetails,
        );

        expect(exception.toString(), 'MobileScannerException(unsupported)');
      },
    );

    test(
      'toString returns formatted string with error details and message',
      () {
        const errorDetails = MobileScannerErrorDetails(
          code: 'TEST_ERROR',
          message: 'Camera not available',
          details: 'Some details',
        );
        const exception = MobileScannerException(
          errorCode: MobileScannerErrorCode.unsupported,
          errorDetails: errorDetails,
        );

        expect(
          exception.toString(),
          'MobileScannerException(unsupported, Camera not available)',
        );
      },
    );

    test('handles all MobileScannerErrorCode values', () {
      for (final errorCode in MobileScannerErrorCode.values) {
        final exception = MobileScannerException(errorCode: errorCode);

        expect(
          exception.errorCode,
          errorCode,
          reason: 'ErrorCode $errorCode should be stored correctly',
        );
        expect(
          exception.toString(),
          contains(errorCode.name),
          reason: 'toString should contain the error code name',
        );
      }
    });

    test('can be used as const', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerDisposed,
        errorDetails: MobileScannerErrorDetails(
          code: 'DISPOSED',
          message: 'Controller was disposed',
        ),
      );

      expect(exception, isA<MobileScannerException>());
    });
  });

  group('$MobileScannerErrorDetails tests', () {
    test('can be constructed with no parameters', () {
      const details = MobileScannerErrorDetails();

      expect(details.code, isNull);
      expect(details.message, isNull);
      expect(details.details, isNull);
    });

    test('can be constructed with all parameters', () {
      const details = MobileScannerErrorDetails(
        code: 'ERROR_CODE',
        message: 'Error message',
        details: 'Additional details',
      );

      expect(details.code, 'ERROR_CODE');
      expect(details.message, 'Error message');
      expect(details.details, 'Additional details');
    });

    test('can be constructed with code only', () {
      const details = MobileScannerErrorDetails(code: 'ONLY_CODE');

      expect(details.code, 'ONLY_CODE');
      expect(details.message, isNull);
      expect(details.details, isNull);
    });

    test('can be constructed with message only', () {
      const details = MobileScannerErrorDetails(message: 'Only message');

      expect(details.code, isNull);
      expect(details.message, 'Only message');
      expect(details.details, isNull);
    });

    test('can be constructed with details only', () {
      const details = MobileScannerErrorDetails(details: {'key': 'value'});

      expect(details.code, isNull);
      expect(details.message, isNull);
      expect(details.details, {'key': 'value'});
    });

    test('details can hold various object types', () {
      const stringDetails = MobileScannerErrorDetails(details: 'string');
      expect(stringDetails.details, 'string');

      const intDetails = MobileScannerErrorDetails(details: 42);
      expect(intDetails.details, 42);

      const listDetails = MobileScannerErrorDetails(details: [1, 2, 3]);
      expect(listDetails.details, [1, 2, 3]);

      const mapDetails = MobileScannerErrorDetails(details: {'a': 1, 'b': 2});
      expect(mapDetails.details, {'a': 1, 'b': 2});
    });

    test('can be used as const', () {
      const details = MobileScannerErrorDetails(
        code: 'CONST_CODE',
        message: 'Const message',
        details: 'Const details',
      );

      expect(details, isA<MobileScannerErrorDetails>());
    });
  });

  group('$MobileScannerBarcodeException tests', () {
    test('can be constructed with a message', () {
      const exception = MobileScannerBarcodeException('Barcode error');

      expect(exception.message, 'Barcode error');
    });

    test('can be constructed with null message', () {
      const exception = MobileScannerBarcodeException(null);

      expect(exception.message, isNull);
    });

    test('implements Exception interface', () {
      const exception = MobileScannerBarcodeException('Test');

      expect(exception, isA<Exception>());
    });

    test('toString returns formatted string with message', () {
      const exception = MobileScannerBarcodeException('Scan failed');

      expect(
        exception.toString(),
        'MobileScannerBarcodeException(Scan failed)',
      );
    });

    test('toString returns default message when message is null', () {
      const exception = MobileScannerBarcodeException(null);

      expect(
        exception.toString(),
        'MobileScannerBarcodeException(Could not detect a barcode in the '
        'input image.)',
      );
    });

    test('toString returns default message when message is empty', () {
      const exception = MobileScannerBarcodeException('');

      expect(
        exception.toString(),
        'MobileScannerBarcodeException(Could not detect a barcode in the '
        'input image.)',
      );
    });

    test('toString returns formatted string with non-empty message', () {
      const exception = MobileScannerBarcodeException('Invalid format');

      expect(
        exception.toString(),
        'MobileScannerBarcodeException(Invalid format)',
      );
    });

    test('can be used as const', () {
      const exception = MobileScannerBarcodeException('Const message');

      expect(exception, isA<MobileScannerBarcodeException>());
    });

    test('handles various message content', () {
      final testMessages = [
        'Simple message',
        r'Message with special chars: !@#$%^&*()',
        'Message with unicode: 你好世界 🎉',
        'Very long message ' * 10,
      ];

      for (final message in testMessages) {
        final exception = MobileScannerBarcodeException(message);

        expect(exception.message, message);
        expect(
          exception.toString(),
          'MobileScannerBarcodeException($message)',
        );
      }
    });
  });
}
