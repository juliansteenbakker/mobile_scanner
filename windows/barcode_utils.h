#ifndef FLUTTER_PLUGIN_BARCODE_UTILS_H_
#define FLUTTER_PLUGIN_BARCODE_UTILS_H_

#include <flutter/encodable_value.h>

#include <ZXing/BarcodeFormat.h>
#include <ZXing/ReadBarcode.h>

namespace mobile_scanner {

/// Maps mobile_scanner BarcodeFormat.rawValue integers to ZXing::BarcodeFormat.
inline ZXing::BarcodeFormat ZXingFormatFromRawValue(int raw) {
  switch (raw) {
    case 1:    return ZXing::BarcodeFormat::Code128;
    case 2:    return ZXing::BarcodeFormat::Code39;
    case 4:    return ZXing::BarcodeFormat::Code93;
    case 8:    return ZXing::BarcodeFormat::Codabar;
    case 16:   return ZXing::BarcodeFormat::DataMatrix;
    case 32:   return ZXing::BarcodeFormat::EAN13;
    case 64:   return ZXing::BarcodeFormat::EAN8;
    case 126:
    case 127:
    case 128:  return ZXing::BarcodeFormat::ITF;
    case 256:  return ZXing::BarcodeFormat::QRCode;
    case 512:  return ZXing::BarcodeFormat::UPCA;
    case 1024: return ZXing::BarcodeFormat::UPCE;
    case 2048: return ZXing::BarcodeFormat::PDF417;
    case 4096: return ZXing::BarcodeFormat::Aztec;
    default:   return ZXing::BarcodeFormat::None;
  }
}

/// Maps ZXing::BarcodeFormat back to mobile_scanner BarcodeFormat.rawValue.
inline int RawValueFromZXingFormat(ZXing::BarcodeFormat fmt) {
  switch (fmt) {
    case ZXing::BarcodeFormat::Code128:   return 1;
    case ZXing::BarcodeFormat::Code39:    return 2;
    case ZXing::BarcodeFormat::Code93:    return 4;
    case ZXing::BarcodeFormat::Codabar:   return 8;
    case ZXing::BarcodeFormat::DataMatrix:return 16;
    case ZXing::BarcodeFormat::EAN13:     return 32;
    case ZXing::BarcodeFormat::EAN8:      return 64;
    case ZXing::BarcodeFormat::ITF:       return 128;
    case ZXing::BarcodeFormat::QRCode:    return 256;
    case ZXing::BarcodeFormat::UPCA:      return 512;
    case ZXing::BarcodeFormat::UPCE:      return 1024;
    case ZXing::BarcodeFormat::PDF417:    return 2048;
    case ZXing::BarcodeFormat::Aztec:     return 4096;
    default:                              return 0;
  }
}

/// Serializes a ZXing::Result into the map format that Barcode.fromNative
/// expects on the Dart side.
inline flutter::EncodableMap SerializeResult(const ZXing::Result& r,
                                             int img_w, int img_h) {
  // Corner points from the position quad.
  auto pos = r.position();
  flutter::EncodableList corners;
  for (int i = 0; i < 4; ++i) {
    corners.push_back(flutter::EncodableMap{
        {flutter::EncodableValue("x"),
         flutter::EncodableValue(static_cast<double>(pos[i].x))},
        {flutter::EncodableValue("y"),
         flutter::EncodableValue(static_cast<double>(pos[i].y))},
    });
  }

  return flutter::EncodableMap{
      {flutter::EncodableValue("format"),
       flutter::EncodableValue(RawValueFromZXingFormat(r.format()))},
      {flutter::EncodableValue("rawValue"),
       flutter::EncodableValue(r.text())},
      {flutter::EncodableValue("displayValue"),
       flutter::EncodableValue(r.text())},
      // BarcodeType.unknown — structured types not available from zxing-cpp.
      {flutter::EncodableValue("type"),
       flutter::EncodableValue(0)},
      {flutter::EncodableValue("corners"),
       flutter::EncodableValue(corners)},
      {flutter::EncodableValue("size"),
       flutter::EncodableValue(flutter::EncodableMap{
           {flutter::EncodableValue("width"),
            flutter::EncodableValue(static_cast<double>(img_w))},
           {flutter::EncodableValue("height"),
            flutter::EncodableValue(static_cast<double>(img_h))},
       })},
  };
}

}  // namespace mobile_scanner

#endif  // FLUTTER_PLUGIN_BARCODE_UTILS_H_
