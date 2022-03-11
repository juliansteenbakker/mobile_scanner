## 1.0.0
BREAKING CHANGES:
This version adds a new allowDuplicates option which now defaults to FALSE. this means that it will only call onDetect once after a scan.
If you still want duplicates, you can set allowDuplicates to true.
This also means that you don't have to check for duplicates yourself anymore.

New features:
* We now have web support! Keep in mind that only QR codes are supported right now.

Bugfixes:
* Fixed hot reload not working.
* Fixed Navigator.of(context).pop() not working in the example app due to duplicate MaterialApp declaration.
* Fixed iOS MLKit version not resolving the latest version.
* Updated all dependencies

## 0.2.0
You can provide a path to controller.analyzeImage(path) in order to scan a local photo from the gallery!
Check out the example app to see how you can use the image_picker plugin to retrieve a photo from
the gallery. Please keep in mind that this feature is only supported on Android and iOS.

Another feature that has been added is a format selector!
Just keep in mind that iOS for now only supports 1 selected barcode.

## 0.1.3
* Fixed crash after asking permission. [#29](https://github.com/juliansteenbakker/mobile_scanner/issues/29)
* Upgraded cameraX from 1.1.0-beta01 to 1.1.0-beta02

## 0.1.2
* MobileScannerArguments is now exported. [#7](https://github.com/juliansteenbakker/mobile_scanner/issues/7)

Bugfixes:
* Fixed application crashing when stop() or start() is called multiple times. [#5](https://github.com/juliansteenbakker/mobile_scanner/issues/5)
* Fixes controller not being disposed correctly. [#23](https://github.com/juliansteenbakker/mobile_scanner/issues/23)
* Catch error when no camera is found. [#19](https://github.com/juliansteenbakker/mobile_scanner/issues/19)

## 0.1.1
mobile_scanner is now compatible with sdk >= 2.12 and flutter >= 2.2.0

## 0.1.0
We now have MacOS support using Apple's Vision framework!
Keep in mind that for now, only the raw value of the barcode object is supported.

Bugfixes:
* Fixed a crash when dispose is called in a overridden method. [#5](https://github.com/juliansteenbakker/mobile_scanner/issues/5) 

## 0.0.3
* Added some API docs and README
* Updated the example app

## 0.0.2
Fixed on iOS:
* You can now set the torch
* You can select the camera you want to use

## 0.0.1
Initial release!
Things working on Android:
* Scanning barcodes using the latest version of MLKit and CameraX!
* Switching camera's
* Toggling of the torch (flash)

Things working on iOS:
* Scanning barcodes using the latest version of MLKit and AVFoundation!
