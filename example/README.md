# mobile_scanner_example

Demonstrates how to use the `mobile_scanner` plugin.

## Run Examples

1. `git clone https://github.com/juliansteenbakker/mobile_scanner.git`
2. `cd mobile_scanner/example/lib`
3. `flutter pub get`
4. `flutter run`

## Examples Overview

### Basic

A minimal example showing the simplest way to get `mobile_scanner` up and running.

* Uses the default `MobileScanner` widget.
* Automatically detects and displays the first barcode.
* No controller or UI controls.
* Ideal starting point for understanding core functionality.

### Advanced

A complete example demonstrating all available features combined into one app.

* Uses `MobileScannerController` for full control.
* Includes:
    - Flashlight toggle
    - Camera switch
    - Start/stop scanner
    - Zoom control
    - Image picker from gallery
    - Scan window overlays
    - ListView of detected barcodes
    - Lifecycle handling
    - PageView integration
* Best suited for exploring the full capabilities of the plugin.
