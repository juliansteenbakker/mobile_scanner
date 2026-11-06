#ifndef FLUTTER_PLUGIN_MOBILE_SCANNER_IMAGE_UTILS_H_
#define FLUTTER_PLUGIN_MOBILE_SCANNER_IMAGE_UTILS_H_

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace mobile_scanner {

// A top-down, tightly packed 32-bit BGRA image.
struct BgraImage {
  std::vector<uint8_t> pixels;
  int width = 0;
  int height = 0;
};

// Loads the first frame of an image file (any format WIC supports).
// The calling thread must have initialized COM.
std::optional<BgraImage> LoadImageFile(const std::wstring& path);

// Encodes a tightly packed 32-bit BGRA image as JPEG, optionally mirroring it
// horizontally. The calling thread must have initialized COM.
std::optional<std::vector<uint8_t>> EncodeJpeg(const uint8_t* bgra, int width,
                                               int height, bool mirror);

}  // namespace mobile_scanner

#endif  // FLUTTER_PLUGIN_MOBILE_SCANNER_IMAGE_UTILS_H_
