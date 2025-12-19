import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/objects/scanner_error_widget.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group('$ScannerErrorWidget tests', () {
    testWidgets('displays error icon', (tester) async {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerErrorWidget(error: error)),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('displays with black background', (tester) async {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerErrorWidget(error: error)),
        ),
      );

      final coloredBox = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(ScannerErrorWidget),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(coloredBox.color, Colors.black);
    });

    testWidgets('displays error icon with white color', (tester) async {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerErrorWidget(error: error)),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.error));
      expect(icon.color, Colors.white);
    });

    testWidgets('shows error code message in debug mode', (tester) async {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerErrorWidget(error: error)),
        ),
      );

      if (kDebugMode) {
        expect(
          find.text(MobileScannerErrorCode.permissionDenied.message),
          findsOneWidget,
        );
      }
    });

    testWidgets('shows error details message when available in debug mode',
        (tester) async {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
        errorDetails: MobileScannerErrorDetails(message: 'Detailed error message'),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerErrorWidget(error: error)),
        ),
      );

      if (kDebugMode) {
        expect(find.text('Detailed error message'), findsOneWidget);
      }
    });

    testWidgets('shows generic error message in release mode', (tester) async {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerErrorWidget(error: error)),
        ),
      );

      if (!kDebugMode) {
        expect(
          find.text(MobileScannerErrorCode.genericError.message),
          findsOneWidget,
        );
      }
    });

    testWidgets('centers content vertically and horizontally', (tester) async {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerErrorWidget(error: error)),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(ScannerErrorWidget),
          matching: find.byType(Center),
        ),
        findsWidgets,
      );
    });

    testWidgets('uses Column for layout', (tester) async {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerErrorWidget(error: error)),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('works with all error codes', (tester) async {
      for (final errorCode in MobileScannerErrorCode.values) {
        final error = MobileScannerException(errorCode: errorCode);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ScannerErrorWidget(error: error)),
          ),
        );

        expect(find.byIcon(Icons.error), findsOneWidget);
      }
    });

    testWidgets('works with error without details', (tester) async {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerAlreadyInitialized,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerErrorWidget(error: error)),
        ),
      );

      expect(find.byType(ScannerErrorWidget), findsOneWidget);
    });
  });
}
