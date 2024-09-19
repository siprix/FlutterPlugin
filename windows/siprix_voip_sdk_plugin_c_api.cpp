#include "include/siprix_voip_sdk/siprix_voip_sdk_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "siprix_voip_sdk_plugin.h"

void SiprixVoipSdkPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  siprix_voip_sdk::SiprixVoipSdkPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
