#include "include/mobile_scanner/mobile_scanner_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "mobile_scanner_plugin.h"

void MobileScannerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  mobile_scanner::MobileScannerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
