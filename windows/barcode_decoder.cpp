#include "barcode_decoder.h"

#include <algorithm>
#include <climits>
#include <string>

#include "ReadBarcode.h"
#include "barcode_format.h"
#include "barcode_payload.h"

namespace mobile_scanner {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

EncodableMap ToMap(const ZXing::Barcode& barcode, int offset_x, int offset_y) {
  const ZXing::Position& position = barcode.position();

  EncodableList corners;
  int min_x = INT_MAX, min_y = INT_MAX, max_x = INT_MIN, max_y = INT_MIN;
  for (const ZXing::PointI& point : position) {
    const int x = point.x + offset_x;
    const int y = point.y + offset_y;
    min_x = std::min(min_x, x);
    min_y = std::min(min_y, y);
    max_x = std::max(max_x, x);
    max_y = std::max(max_y, y);
    corners.emplace_back(EncodableMap{
        {EncodableValue("x"), EncodableValue(static_cast<double>(x))},
        {EncodableValue("y"), EncodableValue(static_cast<double>(y))},
    });
  }

  const std::string text = barcode.text();
  const std::vector<uint8_t>& bytes = barcode.bytes();

  const int32_t type = DetectBarcodeType(text);

  EncodableMap map{
      {EncodableValue("corners"), EncodableValue(corners)},
      {EncodableValue("displayValue"), EncodableValue(text)},
      {EncodableValue("format"),
       EncodableValue(ToDartFormat(barcode.format()))},
      {EncodableValue("rawBytes"),
       EncodableValue(std::vector<uint8_t>(bytes.begin(), bytes.end()))},
      {EncodableValue("rawValue"), EncodableValue(text)},
      {EncodableValue("size"),
       EncodableValue(EncodableMap{
           {EncodableValue("width"),
            EncodableValue(static_cast<double>(max_x - min_x))},
           {EncodableValue("height"),
            EncodableValue(static_cast<double>(max_y - min_y))},
       })},
      {EncodableValue("type"), EncodableValue(type)},
  };
  AddBarcodePayload(type, text, map);
  return map;
}

}  // namespace

BarcodeDecoder::BarcodeDecoder() {
  options_.setFormats(ToZXingFormats({}));
  options_.setTryHarder(true);
  options_.setTryRotate(true);
}

void BarcodeDecoder::SetFormats(const std::vector<int32_t>& dart_formats) {
  options_.setFormats(ToZXingFormats(dart_formats));
}

void BarcodeDecoder::SetMinLineCount(int min_line_count) {
  options_.setMinLineCount(static_cast<uint8_t>(min_line_count));
}

EncodableList BarcodeDecoder::Decode(
    const uint8_t* bgra, int width, int height, int stride,
    const std::optional<ScanWindow>& scan_window) const {
  ZXing::ImageView image(bgra, width, height, ZXing::ImageFormat::BGRA,
                         stride);

  int offset_x = 0;
  int offset_y = 0;
  if (scan_window) {
    offset_x = static_cast<int>(scan_window->left * width);
    offset_y = static_cast<int>(scan_window->top * height);
    const int crop_width =
        static_cast<int>((scan_window->right - scan_window->left) * width);
    const int crop_height =
        static_cast<int>((scan_window->bottom - scan_window->top) * height);
    if (crop_width <= 0 || crop_height <= 0) {
      return EncodableList();
    }
    image = image.cropped(offset_x, offset_y, crop_width, crop_height);
  }

  EncodableList results;
  for (const ZXing::Barcode& barcode : ZXing::ReadBarcodes(image, options_)) {
    if (barcode.isValid()) {
      results.emplace_back(ToMap(barcode, offset_x, offset_y));
    }
  }
  return results;
}

}  // namespace mobile_scanner
