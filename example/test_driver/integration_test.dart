import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  // Grand access to camera with adb, because the Flutter integration test
  // can't interact with native buttons.
  await Process.run('adb', [
    'shell',
    'pm',
    'grant',
    'dev.steenbakker.mobile_scanner.example',
    'android.permission.CAMERA'
  ]);

  await integrationDriver();
}
