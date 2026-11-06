#ifndef FLUTTER_PLUGIN_MOBILE_SCANNER_BARCODE_PAYLOAD_H_
#define FLUTTER_PLUGIN_MOBILE_SCANNER_BARCODE_PAYLOAD_H_

#include <flutter/encodable_value.h>

#include <cstdint>
#include <string>

namespace mobile_scanner {

// Detects the content type of a barcode from its text, returning a
// `BarcodeType.rawValue`. Uses the same heuristics as
// BarcodeTypeDetector.swift, plus MECARD contacts and bare VEVENT calendar
// events, which ML Kit on Android also recognizes.
int32_t DetectBarcodeType(const std::string& text);

// Adds the structured payload for the given `BarcodeType.rawValue` to
// `barcode` (for example `url` or `wifi`), in the format that the Dart
// `fromNative` constructors expect. Types without a payload parser are left
// as is.
void AddBarcodePayload(int32_t type, const std::string& text,
                       flutter::EncodableMap& barcode);

}  // namespace mobile_scanner

#endif  // FLUTTER_PLUGIN_MOBILE_SCANNER_BARCODE_PAYLOAD_H_
