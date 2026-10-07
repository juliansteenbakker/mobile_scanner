#ifndef FLUTTER_PLUGIN_MOBILE_SCANNER_BARCODE_DECODER_H_
#define FLUTTER_PLUGIN_MOBILE_SCANNER_BARCODE_DECODER_H_

#include <flutter/encodable_value.h>

#include <cstdint>
#include <optional>
#include <vector>

#include "ReaderOptions.h"

namespace mobile_scanner {

// A region of interest, in normalized [0, 1] image coordinates with the origin
// at the top left. Matches the `rect` argument of `updateScanWindow`.
struct ScanWindow {
  double left;
  double top;
  double right;
  double bottom;
};

// Decodes barcodes from raw image buffers using zxing-cpp and converts the
// results to the map format that `Barcode.fromNative` expects on the Dart side.
class BarcodeDecoder {
 public:
  BarcodeDecoder();

  // Restricts decoding to the given formats, using the `BarcodeFormat.rawValue`
  // values from Dart. An empty list (or one containing `all`) enables every
  // supported format.
  void SetFormats(const std::vector<int32_t>& dart_formats);

  // Sets how many scan lines of a 1D barcode must agree before it is
  // accepted. Higher values reject spurious matches in noisy images.
  void SetMinLineCount(int min_line_count);

  // Decodes a 32-bit BGRA image. The returned list holds one map per barcode;
  // corner coordinates are in pixels relative to the full image, even when a
  // scan window is given.
  flutter::EncodableList Decode(const uint8_t* bgra, int width, int height,
                                int stride,
                                const std::optional<ScanWindow>& scan_window) const;

 private:
  ZXing::ReaderOptions options_;
};

}  // namespace mobile_scanner

#endif  // FLUTTER_PLUGIN_MOBILE_SCANNER_BARCODE_DECODER_H_
