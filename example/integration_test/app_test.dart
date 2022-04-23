import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // This test needs some local setup before working:
  // 1. Add the screenshot "qr_code.jpg" to your Android emulator camera:
  //    https://stackoverflow.com/a/64922184/8358501
  // 2. Grand the camera permission with
  testWidgets(
    "scan qr code",
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MyHome()));

      await tester.tap(find.text('MobileScanner with Controller'));
      await tester.pumpAndSettle();

      const link = 'https://sharez.one/pGmfH4rTQeuxXbLE6';
      await waitFor(tester, find.text(link));
      expect(
        find.text(link),
        findsOneWidget,
      );
    },
  );
}

/// Wait for the [finder] to appear.
///
/// Workaround for the old FlutterDriver.waitFor. Source:
/// https://github.com/flutter/flutter/issues/88765
Future<void> waitFor(WidgetTester tester, Finder finder) async {
  do {
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 100));
  } while (finder.evaluate().isEmpty);
}
