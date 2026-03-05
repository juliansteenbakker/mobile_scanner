#ifndef FLUTTER_PLUGIN_MOBILE_SCANNER_PLUGIN_H_
#define FLUTTER_PLUGIN_MOBILE_SCANNER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#include <memory>

namespace mobile_scanner {

class FLUTTER_PLUGIN_EXPORT MobileScannerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  MobileScannerPlugin();
  virtual ~MobileScannerPlugin();

  // Disallow copy and assign.
  MobileScannerPlugin(const MobileScannerPlugin&) = delete;
  MobileScannerPlugin& operator=(const MobileScannerPlugin&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  void HandleAnalyzeImage(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace mobile_scanner

#endif  // FLUTTER_PLUGIN_MOBILE_SCANNER_PLUGIN_H_
