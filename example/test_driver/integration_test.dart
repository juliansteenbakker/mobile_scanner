import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  // Grant access to camera with adb, because the Flutter integration test can't
  // interact with native buttons.
  //
  // It's only a workaround for https://github.com/flutter/flutter/issues/12561.
  //
  // We need to grant the access to the camera at this location. A better
  // location would be in CI setup (like in the `run_integration.sh`). But this
  // not possible because in the CI the app is not installed when calling the
  // adb command. Therefore, granting the access will not work. A different good
  // location would be the setUpAll method in the app_test.dart file. But this
  // is also not possible, because this command will be executed from Android
  // app inside the emulator, which will throw an `PermissionDenied` error.
  await Process.run('adb', [
    'shell',
    'pm',
    'grant',
    'dev.steenbakker.mobile_scanner_example',
    'android.permission.CAMERA'
  ]);

  await integrationDriver(
    onScreenshot: (screenshotName, screenshotBytes) async {
      final image = await File('test_results/$screenshotName.png').create(
        // Create the folder "test_results" if it doesn't exist.
        recursive: true,
      );

      image.writeAsBytesSync(screenshotBytes);

      // Return false if the screenshot is invalid.
      return true;
    },
  );
}
