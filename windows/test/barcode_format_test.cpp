#include <gtest/gtest.h>

#include <vector>

#include "barcode_format.h"

namespace mobile_scanner {
namespace test {

namespace {

using Format = ZXing::BarcodeFormat;

ZXing::BarcodeFormats Formats(std::vector<Format> formats) {
  return ZXing::BarcodeFormats(std::move(formats));
}

bool Contains(const ZXing::BarcodeFormats& formats, Format format) {
  for (const Format f : formats) {
    if (f == format) {
      return true;
    }
  }
  return false;
}

}  // namespace

TEST(ToZXingFormats, EmptyAndAllEnableEveryDartFormat) {
  const ZXing::BarcodeFormats all = ToZXingFormats({});
  EXPECT_EQ(ToZXingFormats({0}), all);
  EXPECT_EQ(ToZXingFormats({256, 0}), all);

  // Every enabled format maps back to a Dart format.
  for (const Format format : all) {
    EXPECT_NE(ToDartFormat(format), -1) << ZXing::ToString(format);
  }
  // Formats without a Dart counterpart are not scanned for.
  EXPECT_FALSE(Contains(all, Format::RMQRCode));
  EXPECT_FALSE(Contains(all, Format::DXFilmEdge));
  EXPECT_FALSE(Contains(all, Format::Telepen));
}

TEST(ToZXingFormats, OnlyUnknownFormatsEnableEverything) {
  EXPECT_EQ(ToZXingFormats({-1, 999}), ToZXingFormats({}));
}

TEST(ToZXingFormats, UsesExactVariants) {
  // qrCode must not also find Micro QR or rMQR codes.
  EXPECT_EQ(ToZXingFormats({256}),
            Formats({Format::QRCodeModel1, Format::QRCodeModel2}));
  EXPECT_EQ(ToZXingFormats({16384}), Formats({Format::MicroQRCode}));

  // dataBar must not also find Expanded or Limited codes.
  EXPECT_EQ(ToZXingFormats({32768}),
            Formats({Format::DataBarOmni, Format::DataBarStk,
                     Format::DataBarStkOmni}));
  EXPECT_EQ(ToZXingFormats({65536}),
            Formats({Format::DataBarExp, Format::DataBarExpStk}));
  EXPECT_EQ(ToZXingFormats({131072}), Formats({Format::DataBarLtd}));

  EXPECT_EQ(ToZXingFormats({32}), Formats({Format::EAN13, Format::ISBN}));
  EXPECT_EQ(ToZXingFormats({512}), Formats({Format::UPCA}));
}

TEST(ToZXingFormats, AllItfVariantsEnableItf) {
  for (const int32_t itf : {126, 127, 128}) {
    EXPECT_EQ(ToZXingFormats({itf}), Formats({Format::ITF}));
  }
}

TEST(ToZXingFormats, CombinesFormats) {
  EXPECT_EQ(ToZXingFormats({64, 1024, -1}),
            Formats({Format::EAN8, Format::UPCE}));
}

// The expected values match lib/src/web/zxing_wasm/zxing_wasm_formats.dart.
TEST(ToDartFormat, FoldsVariantsLikeTheWebImplementation) {
  EXPECT_EQ(ToDartFormat(Format::AztecRune), 4096);
  EXPECT_EQ(ToDartFormat(Format::Code32), 2);
  EXPECT_EQ(ToDartFormat(Format::PZN), 2);
  EXPECT_EQ(ToDartFormat(Format::DataBarStk), 32768);
  EXPECT_EQ(ToDartFormat(Format::DataBarExpStk), 65536);
  EXPECT_EQ(ToDartFormat(Format::DataBarLtd), 131072);
  EXPECT_EQ(ToDartFormat(Format::ISBN), 32);
  EXPECT_EQ(ToDartFormat(Format::EAN13), 32);
  EXPECT_EQ(ToDartFormat(Format::ITF14), 128);
  EXPECT_EQ(ToDartFormat(Format::MicroPDF417), 2048);
  EXPECT_EQ(ToDartFormat(Format::QRCodeModel2), 256);
  EXPECT_EQ(ToDartFormat(Format::MicroQRCode), 16384);
  EXPECT_EQ(ToDartFormat(Format::UPCE), 1024);
}

TEST(ToDartFormat, FormatsWithoutDartCounterpartAreUnknown) {
  EXPECT_EQ(ToDartFormat(Format::RMQRCode), -1);
  EXPECT_EQ(ToDartFormat(Format::DXFilmEdge), -1);
  EXPECT_EQ(ToDartFormat(Format::None), -1);
}

}  // namespace test
}  // namespace mobile_scanner
