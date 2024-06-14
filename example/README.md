# mobile_scanner_example

Demonstrates how to use the mobile_scanner plugin.

## Run Examples

1. `git clone https://github.com/juliansteenbakker/mobile_scanner.git`
2. `cd mobile_scanner/example/lib`
3. `flutter pub get`
4. `flutter run`

## Examples Overview

### With Controller

Scanner widget with control buttons overlay. Shows first detected barcode.
(See ListView example for detecting and displaying multiple barcodes at the same time.)

* Displays Flashlight, SwitchCamera and Start/Stop buttons.
* Uses `MobileScannerController` to start/stop, toggle flashlight, switch camera.
* Displays Gallery button to use images as source for analysis.
* Handles changes in AppLifecycleState.

### With ListView

Scanner widget with control buttons overlay. Shows all barcodes detected at the same time in a ListView.

* Displays Flashlight, SwitchCamera and Start/Stop buttons.
* Uses `MobileScannerController` to start/stop, toggle flashlight, switch camera.
* Displays Gallery button to use images as source for analysis.

### With Zoom Slider

Scanner widget with control buttons and zoom slider overlay. Shows first detected barcode.

* Displays Flashlight, SwitchCamera and Start/Stop buttons and zoom slider.
* Uses `MobileScannerController` to start/stop, toggle flashlight, switch camera, set zoom scale.
* Displays Gallery button to use images as source for analysis.

### With Controller (returning image)

Scanner widget with control buttons overlay. Shows the first detected barcode and the captured image.

* Displays Flashlight, SwitchCamera and Start/Stop buttons.
* Uses `MobileScannerController` to start/stop, toggle flashlight, switch camera.
* Displays captured image that contains the detected barcode.

### With Page View

Scanner widget in one of many pages that can be swiped horizontally. Starts and stops scanner depending on page visibility.

* Shows first detected barcode.

### With Scan Window

Scanner widget with scan window overlay. Barcodes are only detected inside the scan window.

* Draws scan window - a half-transparent overlay with a cut out middle part.
* Draws bounding box around (first) detected barcode. (not working on every device)

### With Overlay

Scanner widget with scan window overlay. Barcodes are only detected inside the scan window.

* Draws scan window - a half-transparent overlay with a cut out middle part that has a border with rounded corners.
* Displays Flashlight, SwitchCamera buttons.
* Uses `MobileScannerController` to toggle flashlight, switch camera.
