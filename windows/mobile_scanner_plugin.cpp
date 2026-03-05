#include "mobile_scanner_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <ReadBarcode.h>
#include <ReaderOptions.h>

#include "barcode_utils.h"
#include "image_loader.h"

#include <memory>
#include <string>
#include <vector>

namespace mobile_scanner {

// static
void MobileScannerPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(),
          "dev.steenbakker.mobile_scanner/scanner/method",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<MobileScannerPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

MobileScannerPlugin::MobileScannerPlugin() {}

MobileScannerPlugin::~MobileScannerPlugin() {}

void MobileScannerPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() == "analyzeImage") {
    HandleAnalyzeImage(method_call, std::move(result));
  } else {
    result->NotImplemented();
  }
}

void MobileScannerPlugin::HandleAnalyzeImage(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto *args =
      std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (!args) {
    result->Error("INVALID_ARGS", "Expected a map argument");
    return;
  }

  // Extract filePath (required).
  auto path_it = args->find(flutter::EncodableValue("filePath"));
  if (path_it == args->end() ||
      !std::holds_alternative<std::string>(path_it->second)) {
    result->Error("INVALID_ARGS", "Missing or invalid 'filePath'");
    return;
  }
  const std::string &file_path =
      std::get<std::string>(path_it->second);

  // Extract optional formats list.
  ZXing::ReaderOptions opts;  // default: all formats
  auto fmt_it = args->find(flutter::EncodableValue("formats"));
  if (fmt_it != args->end() &&
      std::holds_alternative<flutter::EncodableList>(fmt_it->second)) {
    const auto &fmt_list =
        std::get<flutter::EncodableList>(fmt_it->second);
    if (!fmt_list.empty()) {
      std::vector<ZXing::BarcodeFormat> fmt_vec;
      for (const auto &v : fmt_list) {
        if (std::holds_alternative<int32_t>(v)) {
          auto fmt = ZXingFormatFromRawValue(std::get<int32_t>(v));
          if (fmt != ZXing::BarcodeFormat::None) {
            fmt_vec.push_back(fmt);
          }
        }
      }
      if (!fmt_vec.empty()) {
        opts.setFormats(ZXing::BarcodeFormats(std::move(fmt_vec)));
      }
    }
  }

  // Load image via WIC.
  ImageData img;
  try {
    img = LoadImageAsRGBA(Utf8ToWide(file_path));
  } catch (const std::exception &e) {
    result->Error("FILE_ERROR", e.what());
    return;
  }

  // RGBA = 4 bytes per pixel (R, G, B, A order) — matches WIC RGBA output.
  auto results = ZXing::ReadBarcodes(
      ZXing::ImageView(img.pixels.data(), img.width, img.height,
                       ZXing::ImageFormat::RGBA),
      opts);

  if (results.empty()) {
    // Return null — Dart interprets this as no barcodes found.
    result->Success(flutter::EncodableValue());
    return;
  }

  flutter::EncodableList barcode_list;
  barcode_list.reserve(results.size());
  for (const auto &r : results) {
    barcode_list.push_back(
        flutter::EncodableValue(SerializeResult(r, img.width, img.height)));
  }

  result->Success(flutter::EncodableMap{
      {flutter::EncodableValue("data"),
       flutter::EncodableValue(barcode_list)},
  });
}

}  // namespace mobile_scanner
