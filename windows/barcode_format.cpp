#include "barcode_format.h"

#include <algorithm>

namespace mobile_scanner {

namespace {

using Format = ZXing::BarcodeFormat;

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
// Shared by the deprecated `itf` and by `itf14`.
constexpr int32_t kDartFormatItf = 128;
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

constexpr int32_t kAllDartFormats[] = {
    kDartFormatCode128,   kDartFormatCode39,          kDartFormatCode93,
    kDartFormatCodabar,   kDartFormatDataMatrix,      kDartFormatEan13,
    kDartFormatEan8,      kDartFormatItf,             kDartFormatQrCode,
    kDartFormatUpcA,      kDartFormatUpcE,            kDartFormatPdf417,
    kDartFormatAztec,     kDartFormatMaxiCode,        kDartFormatMicroQrCode,
    kDartFormatDataBar,   kDartFormatDataBarExpanded, kDartFormatDataBarLimited,
};

// The zxing-cpp formats to scan for a Dart format. Symbologies whose variants
// all map back to the same Dart format (like Code 39 or PDF417) are enabled
// as a whole; the others list the matching variants.
std::vector<Format> ZXingFormatsFor(int32_t dart_format) {
  switch (dart_format) {
    case kDartFormatCode128:
      return {Format::Code128};
    case kDartFormatCode39:
      return {Format::Code39};
    case kDartFormatCode93:
      return {Format::Code93};
    case kDartFormatCodabar:
      return {Format::Codabar};
    case kDartFormatDataMatrix:
      return {Format::DataMatrix};
    case kDartFormatEan13:
      // ISBNs are EAN-13 codes.
      return {Format::EAN13, Format::ISBN};
    case kDartFormatEan8:
      return {Format::EAN8};
    case kDartFormatItf2of5:
    case kDartFormatItf2of5WithChecksum:
    case kDartFormatItf:
      return {Format::ITF};
    case kDartFormatQrCode:
      return {Format::QRCodeModel1, Format::QRCodeModel2};
    case kDartFormatUpcA:
      return {Format::UPCA};
    case kDartFormatUpcE:
      return {Format::UPCE};
    case kDartFormatPdf417:
      return {Format::PDF417};
    case kDartFormatAztec:
      return {Format::Aztec};
    case kDartFormatMaxiCode:
      return {Format::MaxiCode};
    case kDartFormatMicroQrCode:
      return {Format::MicroQRCode};
    case kDartFormatDataBar:
      return {Format::DataBarOmni, Format::DataBarStk, Format::DataBarStkOmni};
    case kDartFormatDataBarExpanded:
      return {Format::DataBarExp, Format::DataBarExpStk};
    case kDartFormatDataBarLimited:
      return {Format::DataBarLtd};
    default:
      return {};
  }
}

}  // namespace

ZXing::BarcodeFormats ToZXingFormats(const std::vector<int32_t>& dart_formats) {
  const bool all =
      dart_formats.empty() ||
      std::find(dart_formats.begin(), dart_formats.end(), kDartFormatAll) !=
          dart_formats.end();

  std::vector<Format> formats;
  for (const int32_t dart_format : all ? std::vector<int32_t>(
                                             std::begin(kAllDartFormats),
                                             std::end(kAllDartFormats))
                                       : dart_formats) {
    for (const Format format : ZXingFormatsFor(dart_format)) {
      formats.push_back(format);
    }
  }

  // Only unknown formats were requested; scan for everything rather than
  // nothing, as before.
  if (formats.empty()) {
    return ToZXingFormats({kDartFormatAll});
  }
  return ZXing::BarcodeFormats(std::move(formats));
}

int32_t ToDartFormat(ZXing::BarcodeFormat format) {
  switch (format) {
    case Format::Aztec:
    case Format::AztecCode:
    case Format::AztecRune:
      return kDartFormatAztec;
    case Format::Codabar:
      return kDartFormatCodabar;
    case Format::Code39:
    case Format::Code39Std:
    case Format::Code39Ext:
    case Format::Code32:
    case Format::PZN:
      return kDartFormatCode39;
    case Format::Code93:
      return kDartFormatCode93;
    case Format::Code128:
      return kDartFormatCode128;
    case Format::DataBar:
    case Format::DataBarOmni:
    case Format::DataBarStk:
    case Format::DataBarStkOmni:
      return kDartFormatDataBar;
    case Format::DataBarExp:
    case Format::DataBarExpStk:
      return kDartFormatDataBarExpanded;
    case Format::DataBarLtd:
      return kDartFormatDataBarLimited;
    case Format::DataMatrix:
      return kDartFormatDataMatrix;
    case Format::EAN8:
      return kDartFormatEan8;
    case Format::EAN13:
    case Format::ISBN:
      return kDartFormatEan13;
    case Format::ITF:
    case Format::ITF14:
      return kDartFormatItf;
    case Format::MaxiCode:
      return kDartFormatMaxiCode;
    case Format::PDF417:
    case Format::CompactPDF417:
    case Format::MicroPDF417:
      return kDartFormatPdf417;
    case Format::QRCode:
    case Format::QRCodeModel1:
    case Format::QRCodeModel2:
      return kDartFormatQrCode;
    case Format::MicroQRCode:
      return kDartFormatMicroQrCode;
    case Format::UPCA:
      return kDartFormatUpcA;
    case Format::UPCE:
      return kDartFormatUpcE;
    default:
      return kDartFormatUnknown;
  }
}

}  // namespace mobile_scanner
