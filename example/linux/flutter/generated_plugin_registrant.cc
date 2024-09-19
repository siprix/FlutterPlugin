//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <siprix_voip_sdk/siprix_voip_sdk_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) siprix_voip_sdk_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SiprixVoipSdkPlugin");
  siprix_voip_sdk_plugin_register_with_registrar(siprix_voip_sdk_registrar);
}
