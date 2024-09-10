# mobile_scanner

[![pub package](https://img.shields.io/pub/v/mobile_scanner.svg)](https://pub.dev/packages/mobile_scanner)
[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)
[![mobile_scanner](https://github.com/juliansteenbakker/mobile_scanner/actions/workflows/flutter.yml/badge.svg)](https://github.com/juliansteenbakker/mobile_scanner/actions/workflows/flutter.yml)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/juliansteenbakker?label=like%20my%20work?%20sponsor%20me!)](https://github.com/sponsors/juliansteenbakker)

A universal scanner for Flutter based on MLKit. Uses CameraX on Android and AVFoundation on iOS.

## Breaking Changes v5.0.0
Version 5.0.0 brings some breaking changes. However, some are reverted in version 5.1.0. Please see the list below for all breaking changes, and Changelog.md for a more detailed list.

* ~~The `autoStart` attribute has been removed from the `MobileScannerController`. The controller should be manually started on-demand.~~ (Reverted in version 5.1.0)
* ~~A controller is now required for the `MobileScanner` widget.~~ (Reverted in version 5.1.0)
* ~~The `onDetect` method has been removed from the `MobileScanner` widget. Instead, listen to `MobileScannerController.barcodes` directly.~~ (Reverted in version 5.1.0)
* The `width` and `height` of `BarcodeCapture` have been removed, in favor of `size`.
* The `raw` attribute is now `Object?` instead of `dynamic`, so that it participates in type promotion.
* The `MobileScannerArguments` class has been removed from the public API, as it is an internal type.
* The `cameraFacingOverride` named argument for the `start()` method has been renamed to `cameraDirection`.
* The `analyzeImage` function now correctly returns a `BarcodeCapture?` instead of a boolean.
* The `formats` attribute of the `MobileScannerController` is now non-null.
* The `MobileScannerState` enum has been renamed to `MobileScannerAuthorizationState`.
* The various `ValueNotifier`s for the camera state have been removed. Use the `value` of the `MobileScannerController` instead.
* The `hasTorch` getter has been removed. Instead, use the torch state of the controller's value.
* The `TorchState` enum now provides a new value for unavailable flashlights.
* The  `onPermissionSet`, `onStart` and `onScannerStarted` methods have been removed from the `MobileScanner` widget. Instead, await `MobileScannerController.start()`.
* The `startDelay` has been removed from the `MobileScanner` widget. Instead, use a delay between manual starts of one or more controllers.
* The `overlay` widget of the `MobileScanner` has been replaced by a new property, `overlayBuilder`, which provides the constraints for the overlay.
* The torch can no longer be toggled on the web, as this is only available for image tracks and not video tracks. As a result the torch state for the web will always be `TorchState.unavailable`.
* The zoom scale can no longer be modified on the web, as this is only available for image tracks and not video tracks. As a result, the zoom scale will always be `1.0`.

## Features Supported

See the example app for detailed implementation information.

| Features               | Android            | iOS                | macOS                | Web |
|------------------------|--------------------|--------------------|----------------------|-----|
| analyzeImage (Gallery) | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:   | :x: |
| returnImage            | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:   | :x: |
| scanWindow             | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:   | :x: |

## Platform Support

| Android | iOS | macOS | Web | Linux | Windows |
|---------|-----|-------|-----|-------|---------|
| ✔       | ✔   | ✔     | ✔   | :x:   | :x:     |

## Platform specific setup

### Android
This package uses by default the **bundled version** of MLKit Barcode-scanning for Android. This version is immediately available to the device. But it will increase the size of the app by approximately 3 to 10 MB.

The alternative is to use the **unbundled version** of MLKit Barcode-scanning for Android. This version is downloaded on first use via Google Play Services. It increases the app size by around 600KB.

[You can read more about the difference between the two versions here.](https://developers.google.com/ml-kit/vision/barcode-scanning/android)

To use the **unbundled version** of the MLKit Barcode-scanning, add the following line to your `/android/gradle.properties` file:
```
dev.steenbakker.mobile_scanner.useUnbundled=true
```

### iOS
**Add the following keys to your Info.plist file, located in <project root>/ios/Runner/Info.plist:**
NSCameraUsageDescription - describe why your app needs access to the camera. This is called Privacy - Camera Usage Description in the visual editor.

**If you want to use the local gallery feature from [image_picker](https://pub.dev/packages/image_picker)**
NSPhotoLibraryUsageDescription - describe why your app needs permission for the photo library. This is called Privacy - Photo Library Usage Description in the visual editor.

  Example,
  ```
  <key>NSCameraUsageDescription</key>
  <string>This app needs camera access to scan QR codes</string>

  <key>NSPhotoLibraryUsageDescription</key>
  <string>This app needs photos access to get QR code from photo library</string>
  ```


### macOS
Ensure that you granted camera permission in XCode -> Signing & Capabilities:

<img width="696" alt="Screenshot of XCode where Camera is checked" src="https://user-images.githubusercontent.com/24459435/193464115-d76f81d0-6355-4cb2-8bee-538e413a3ad0.png">

## Web

As of version 5.0.0 adding the barcode scanning library script to the `index.html` is no longer required,
as the script is automatically loaded on first use.

### Providing a mirror for the barcode scanning library

If a different mirror is needed to load the barcode scanning library,
the source URL can be set beforehand.

```dart
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

final String scriptUrl = // ...

if (kIsWeb) {
  MobileScannerPlatform.instance.setBarcodeLibraryScriptUrl(scriptUrl);
}
```

## Usage

Import the package with `package:mobile_scanner/mobile_scanner.dart`.

Create a new `MobileScannerController` controller, using the required options.
Provide a `StreamSubscription` for the barcode events.

```dart
final MobileScannerController controller = MobileScannerController(
  // required options for the scanner
);

StreamSubscription<Object?>? _subscription;
```

Ensure that your `State` class mixes in `WidgetsBindingObserver`, to handle lifecyle changes:

```dart
class MyState extends State<MyStatefulWidget> with WidgetsBindingObserver {
  // ...

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it.
    // Permission dialogs can trigger lifecycle changes before the controller is ready.
    if (!controller.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed.
        // Don't forget to resume listening to the barcode events.
        _subscription = controller.barcodes.listen(_handleBarcode);

        unawaited(controller.start());
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused.
        // Also stop the barcode events subscription.
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(controller.stop());
    }
  }

  // ...
}
```

Then, start the scanner in `void initState()`:

```dart
@override
void initState() {
  super.initState();
  // Start listening to lifecycle changes.
  WidgetsBinding.instance.addObserver(this);

  // Start listening to the barcode events.
  _subscription = controller.barcodes.listen(_handleBarcode);

  // Finally, start the scanner itself.
  unawaited(controller.start());
}
```

Finally, dispose of the the `MobileScannerController` when you are done with it.

```dart
@override
Future<void> dispose() async {
  // Stop listening to lifecycle changes.
  WidgetsBinding.instance.removeObserver(this);
  // Stop listening to the barcode events.
  unawaited(_subscription?.cancel());
  _subscription = null;
  // Dispose the widget itself.
  super.dispose();
  // Finally, dispose of the controller.
  await controller.dispose();
}
```

To display the camera preview, pass the controller to a `MobileScanner` widget.

See the [examples](example/README.md) for runnable examples of various usages,
such as the basic usage, applying a scan window, or retrieving images from the barcodes.
