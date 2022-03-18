# mobile_scanner

[![pub package](https://img.shields.io/pub/v/mobile_scanner.svg)](https://pub.dev/packages/mobile_scanner)
[![mobile_scanner](https://github.com/juliansteenbakker/mobile_scanner/actions/workflows/flutter.yml/badge.svg)](https://github.com/juliansteenbakker/mobile_scanner/actions/workflows/flutter.yml)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/juliansteenbakker?label=Want%20personal%20and%20fast%20support%3F%20Sponsor%20me%20and%20I%27ll%20contact%20you%21)](https://github.com/sponsors/juliansteenbakker)

A universal barcode and QR code scanner for Flutter based on MLKit. Uses CameraX on Android, AVFoundation on iOS and Apple Vision & AVFoundation on macOS. 

## Platform Support

| Android | iOS | MacOS | Web | Linux | Windows |
| :-----: | :-: | :---: | :-: | :---: | :-----: |
|   ✔️    | ✔️   |  ✔️  | ✔️  |     |      |

### Android
SDK 21 and newer. Reason: CameraX requires at least SDK 21.

This packages uses the **bundled version** of MLKit Barcode-scanning for Android. This version is more accurate and immediately available to devices. However, this version will increas the size of the app with approximately 3 to 10 MB. The alternative for this is to use the **unbundled version** of MLKit Barcode-scanning for Android. This version is older than the bundled version however this only increases the size by around 600KB. 

To use this version you must alter the mobile_scanner gradle file to replace `com.google.mlkit:barcode-scanning:17.0.2` with `com.google.android.gms:play-services-mlkit-barcode-scanning:18.0.0`. Keep in mind that if you alter the gradle files directly in your project it can be overriden when you update your pubspec.yaml. I am still searching for a way to properly replace the module in gradle but have yet to find one.

[You can read more about the difference between the two versions here.](https://developers.google.com/ml-kit/vision/barcode-scanning/android)

### iOS
iOS 11 and newer. Reason: MLKit for iOS requires at least iOS 11 and a [64bit device](https://developers.google.com/ml-kit/migration/ios).

**Add the following keys to your Info.plist file, located in <project root>/ios/Runner/Info.plist:**

NSCameraUsageDescription - describe why your app needs access to the camera. This is called Privacy - Camera Usage Description in the visual editor.

**If you want to use the local gallery feature from [image_picker](https://pub.dev/packages/image_picker)**
  
NSPhotoLibraryUsageDescription - describe why your app needs permission for the photo library. This is called Privacy - Photo Library Usage Description in the visual editor.
  
### macOS
macOS 10.13 or newer. Reason: Apple Vision library.

### Web
Add this to `web/index.html`:

```html
<script src="https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.min.js"></script>
```

Web only supports QR codes for now. 
Do you have experience with Flutter Web development? [Help me with migrating from jsQR to qr-scanner for full barcode support!](https://github.com/juliansteenbakker/mobile_scanner/issues/54)

## Features Supported

| Features               | Android            | iOS                | macOS | Web |
|------------------------|--------------------|--------------------|-------|-----|
| analyzeImage (Gallery) | :heavy_check_mark: | :heavy_check_mark: |   :x:    |  :x:   |

## Usage

Import `package:mobile_scanner/mobile_scanner.dart`, and use the widget with or without the controller.

If you don't provide a controller, you can't control functions like the torch(flash) or switching camera.

If you don't set allowDuplicates to false, you can get multiple scans in a very short time, causing things like pop() to fire lots of times.

Example without controller:

```dart
import 'package:mobile_scanner/mobile_scanner.dart';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Scanner')),
      body: MobileScanner(
          allowDuplicates: false,
          onDetect: (barcode, args) {
            final String code = barcode.rawValue;
            debugPrint('Barcode found! $code');
          }),
    );
  }
```

Example with controller and initial values:

```dart
import 'package:mobile_scanner/mobile_scanner.dart';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Scanner')),
      body: MobileScanner(
          allowDuplicates: false,
          controller: MobileScannerController(
            facing: CameraFacing.front, torchEnabled: true),
          onDetect: (barcode, args) {
            final String code = barcode.rawValue;
            debugPrint('Barcode found! $code');
          }),
    );
  }
```

Example with controller and torch & camera controls:

```dart
import 'package:mobile_scanner/mobile_scanner.dart';

  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Mobile Scanner'),
          actions: [
            IconButton(
              color: Colors.white,
              icon: ValueListenableBuilder(
                valueListenable: cameraController.torchState,
                builder: (context, state, child) {
                  switch (state as TorchState) {
                    case TorchState.off:
                      return const Icon(Icons.flash_off, color: Colors.grey);
                    case TorchState.on:
                      return const Icon(Icons.flash_on, color: Colors.yellow);
                  }
                },
              ),
              iconSize: 32.0,
              onPressed: () => cameraController.toggleTorch(),
            ),
            IconButton(
              color: Colors.white,
              icon: ValueListenableBuilder(
                valueListenable: cameraController.cameraFacingState,
                builder: (context, state, child) {
                  switch (state as CameraFacing) {
                    case CameraFacing.front:
                      return const Icon(Icons.camera_front);
                    case CameraFacing.back:
                      return const Icon(Icons.camera_rear);
                  }
                },
              ),
              iconSize: 32.0,
              onPressed: () => cameraController.switchCamera(),
            ),
          ],
        ),
        body: MobileScanner(
            allowDuplicates: false,
            controller: cameraController,
            onDetect: (barcode, args) {
              final String code = barcode.rawValue;
              debugPrint('Barcode found! $code');
            }));
  }
```
