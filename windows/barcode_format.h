#ifndef FLUTTER_PLUGIN_MOBILE_SCANNER_BARCODE_FORMAT_H_
#define FLUTTER_PLUGIN_MOBILE_SCANNER_BARCODE_FORMAT_H_

#include <cstdint>
#include <vector>

#include "BarcodeFormat.h"

namespace mobile_scanner {

// Converts `BarcodeFormat.rawValue` values from Dart to the zxing-cpp formats
// to scan for. An empty list (or one containing `all`) gives every format
// that has a Dart counterpart.
//
// Formats map to the exact zxing-cpp variants rather than whole symbologies,
// so that for example `qrCode` does not also find Micro QR or rMQR codes.
ZXing::BarcodeFormats ToZXingFormats(const std::vector<int32_t>& dart_formats);

// Converts a zxing-cpp format to a `BarcodeFormat.rawValue`, folding variants
// into their Dart format (for example ISBN into ean13). Matches the mapping in
// lib/src/web/zxing_wasm/zxing_wasm_formats.dart, which uses the same names.
int32_t ToDartFormat(ZXing::BarcodeFormat format);

}  // namespace mobile_scanner

#endif  // FLUTTER_PLUGIN_MOBILE_SCANNER_BARCODE_FORMAT_H_
