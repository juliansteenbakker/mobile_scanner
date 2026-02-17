import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner_example/widgets/scanner_error_widget.dart';

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

      final ColoredBox coloredBox = tester.widget<ColoredBox>(
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

      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.error));
      expect(icon.color, Colors.white);
    });

    testWidgets('displays error code message', (tester) async {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerErrorWidget(error: error)),
        ),
      );

      expect(
        find.text(MobileScannerErrorCode.permissionDenied.message),
        findsOneWidget,
      );
    });

    testWidgets('displays error details message when available', (
      tester,
    ) async {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
        errorDetails: MobileScannerErrorDetails(
          message: 'Detailed error message',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerErrorWidget(error: error)),
        ),
      );

      expect(find.text('Detailed error message'), findsOneWidget);
    });

    testWidgets('displays both error code and details when available', (
      tester,
    ) async {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerAlreadyInitialized,
        errorDetails: MobileScannerErrorDetails(
          message: 'Controller was initialized twice',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerErrorWidget(error: error)),
        ),
      );

      expect(
        find.text(MobileScannerErrorCode.controllerAlreadyInitialized.message),
        findsOneWidget,
      );
      expect(
        find.text('Controller was initialized twice'),
        findsOneWidget,
      );
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
      for (final MobileScannerErrorCode errorCode
          in MobileScannerErrorCode.values) {
        final error = MobileScannerException(errorCode: errorCode);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ScannerErrorWidget(error: error)),
          ),
        );

        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.text(errorCode.message), findsOneWidget);
      }
    });

    testWidgets('handles error details with null message', (tester) async {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
        errorDetails: MobileScannerErrorDetails(),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerErrorWidget(error: error)),
        ),
      );

      // Should only find the error code message, not an additional details text
      final Iterable<Text> textWidgets = tester.widgetList<Text>(
        find.byType(Text),
      );
      expect(textWidgets.length, 1);
      expect(
        find.text(MobileScannerErrorCode.genericError.message),
        findsOneWidget,
      );
    });
  });
}
