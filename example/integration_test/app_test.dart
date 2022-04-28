import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner_example/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
      as IntegrationTestWidgetsFlutterBinding;

  // Before running the test, add the screenshot "qr_code.jpg" to your Android
  // emulator camera: https://stackoverflow.com/a/64922184/8358501
  testWidgets(
    "scan qr code",
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MyHome()));

      await tester.tap(find.text('MobileScanner with Controller'));
      await tester.pumpAndSettle();

      const link = 'https://sharez.one/pGmfH4rTQeuxXbLE6_';
      try {
        await waitFor(
          tester,
          find.text(link),
          timeout: const Duration(seconds: 3),
        );
      } catch (e) {
        await tester.tap(find.byKey(const Key('camera_switch')));
        await tester.pump();

        try {
          await waitFor(
            tester,
            find.text(link),
            timeout: const Duration(seconds: 3),
          );
        } catch (e) {
          await binding.convertFlutterSurfaceToImage();

          // Trigger a frame.
          await tester.pumpAndSettle();
          await binding.takeScreenshot('screenshot-1');
        }
      }

      expect(
        find.text(link),
        findsOneWidget,
      );
    },
  );
}

/// Wait for the [finder] to appear.
///
/// Throws an [Exception] when the timeout is reached.
///
/// Workaround for the old FlutterDriver.waitFor. Source:
/// https://github.com/flutter/flutter/issues/88765
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);

  do {
    if (DateTime.now().isAfter(end)) {
      throw Exception('Timed out waiting for $finder');
    }

    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 100));
  } while (finder.evaluate().isEmpty);
}
