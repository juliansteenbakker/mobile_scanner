#include "barcode_decoder.h"

#include <algorithm>
#include <climits>
#include <string>

#include "ReadBarcode.h"
#include "barcode_payload.h"

namespace mobile_scanner {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// `BarcodeFormat.rawValue` values from lib/src/enums/barcode_format.dart.
constexpr int32_t kDartFormatUnknown = -1;
constexpr int32_t kDartFormatAll = 0;
constexpr int32_t kDartFormatCode128 = 1;
constexpr int32_t kDartFormatCode39 = 2;
constexpr int32_t kDartFormatCode93 = 4;
constexpr int32_t kDartFormatCodabar = 8;
constexpr int32_t kDartFormatDataMatrix = 16;
constexpr int32_t kDartFormatEan13 = 32;
constexpr int32_t kDartFormatEan8 = 64;
constexpr int32_t kDartFormatItf2of5 = 126;
constexpr int32_t kDartFormatItf2of5WithChecksum = 127;
constexpr int32_t kDartFormatItf14 = 128;
constexpr int32_t kDartFormatQrCode = 256;
constexpr int32_t kDartFormatUpcA = 512;
constexpr int32_t kDartFormatUpcE = 1024;
constexpr int32_t kDartFormatPdf417 = 2048;
constexpr int32_t kDartFormatAztec = 4096;
constexpr int32_t kDartFormatMaxiCode = 8192;
constexpr int32_t kDartFormatMicroQrCode = 16384;
constexpr int32_t kDartFormatDataBar = 32768;
constexpr int32_t kDartFormatDataBarExpanded = 65536;
constexpr int32_t kDartFormatDataBarLimited = 131072;

std::optional<ZXing::BarcodeFormat> FromDartFormat(int32_t format) {
  switch (format) {
    case kDartFormatCode128:
      return ZXing::BarcodeFormat::Code128;
    case kDartFormatCode39:
      return ZXing::BarcodeFormat::Code39;
    case kDartFormatCode93:
      return ZXing::BarcodeFormat::Code93;
    case kDartFormatCodabar:
      return ZXing::BarcodeFormat::Codabar;
    case kDartFormatDataMatrix:
      return ZXing::BarcodeFormat::DataMatrix;
    case kDartFormatEan13:
      return ZXing::BarcodeFormat::EAN13;
    case kDartFormatEan8:
      return ZXing::BarcodeFormat::EAN8;
    case kDartFormatItf2of5:
    case kDartFormatItf2of5WithChecksum:
    case kDartFormatItf14:
      return ZXing::BarcodeFormat::ITF;
    case kDartFormatQrCode:
      return ZXing::BarcodeFormat::QRCode;
    case kDartFormatUpcA:
      return ZXing::BarcodeFormat::UPCA;
    case kDartFormatUpcE:
      return ZXing::BarcodeFormat::UPCE;
    case kDartFormatPdf417:
      return ZXing::BarcodeFormat::PDF417;
    case kDartFormatAztec:
      return ZXing::BarcodeFormat::Aztec;
    case kDartFormatMaxiCode:
      return ZXing::BarcodeFormat::MaxiCode;
    case kDartFormatMicroQrCode:
      return ZXing::BarcodeFormat::MicroQRCode;
    case kDartFormatDataBar:
      return ZXing::BarcodeFormat::DataBar;
    case kDartFormatDataBarExpanded:
      return ZXing::BarcodeFormat::DataBarExpanded;
    case kDartFormatDataBarLimited:
      return ZXing::BarcodeFormat::DataBarLimited;
    default:
      return std::nullopt;
  }
}

int32_t ToDartFormat(ZXing::BarcodeFormat format) {
  switch (format) {
    case ZXing::BarcodeFormat::Code128:
      return kDartFormatCode128;
    case ZXing::BarcodeFormat::Code39:
      return kDartFormatCode39;
    case ZXing::BarcodeFormat::Code93:
      return kDartFormatCode93;
    case ZXing::BarcodeFormat::Codabar:
      return kDartFormatCodabar;
    case ZXing::BarcodeFormat::DataMatrix:
      return kDartFormatDataMatrix;
    case ZXing::BarcodeFormat::EAN13:
      return kDartFormatEan13;
    case ZXing::BarcodeFormat::EAN8:
      return kDartFormatEan8;
    case ZXing::BarcodeFormat::ITF:
      return kDartFormatItf14;
    case ZXing::BarcodeFormat::QRCode:
      return kDartFormatQrCode;
    case ZXing::BarcodeFormat::UPCA:
      return kDartFormatUpcA;
    case ZXing::BarcodeFormat::UPCE:
      return kDartFormatUpcE;
    case ZXing::BarcodeFormat::PDF417:
      return kDartFormatPdf417;
    case ZXing::BarcodeFormat::Aztec:
      return kDartFormatAztec;
    case ZXing::BarcodeFormat::MaxiCode:
      return kDartFormatMaxiCode;
    case ZXing::BarcodeFormat::MicroQRCode:
      return kDartFormatMicroQrCode;
    case ZXing::BarcodeFormat::DataBar:
      return kDartFormatDataBar;
    case ZXing::BarcodeFormat::DataBarExpanded:
      return kDartFormatDataBarExpanded;
    case ZXing::BarcodeFormat::DataBarLimited:
      return kDartFormatDataBarLimited;
    default:
      return kDartFormatUnknown;
  }
}

// Every format that has a Dart counterpart.
ZXing::BarcodeFormats AllSupportedFormats() {
  return ZXing::BarcodeFormat::Aztec | ZXing::BarcodeFormat::Codabar |
         ZXing::BarcodeFormat::Code39 | ZXing::BarcodeFormat::Code93 |
         ZXing::BarcodeFormat::Code128 | ZXing::BarcodeFormat::DataBar |
         ZXing::BarcodeFormat::DataBarExpanded |
         ZXing::BarcodeFormat::DataBarLimited |
         ZXing::BarcodeFormat::DataMatrix | ZXing::BarcodeFormat::EAN8 |
         ZXing::BarcodeFormat::EAN13 | ZXing::BarcodeFormat::ITF |
         ZXing::BarcodeFormat::MaxiCode | ZXing::BarcodeFormat::PDF417 |
         ZXing::BarcodeFormat::QRCode | ZXing::BarcodeFormat::UPCA |
         ZXing::BarcodeFormat::UPCE | ZXing::BarcodeFormat::MicroQRCode;
}

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
  const ZXing::ByteArray& bytes = barcode.bytes();

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
  options_.setFormats(AllSupportedFormats());
  options_.setTryHarder(true);
  options_.setTryRotate(true);
}

void BarcodeDecoder::SetFormats(const std::vector<int32_t>& dart_formats) {
  ZXing::BarcodeFormats formats;
  for (const int32_t dart_format : dart_formats) {
    if (dart_format == kDartFormatAll) {
      formats = AllSupportedFormats();
      break;
    }
    if (const auto format = FromDartFormat(dart_format)) {
      formats |= *format;
    }
  }
  options_.setFormats(formats.empty() ? AllSupportedFormats() : formats);
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
