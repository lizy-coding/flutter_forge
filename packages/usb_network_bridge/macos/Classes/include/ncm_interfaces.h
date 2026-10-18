#ifndef FORGE_USB_NCM_INTERFACES_H
#define FORGE_USB_NCM_INTERFACES_H

#include <stdint.h>

#pragma pack(push, 1)
typedef struct {
  uint32_t interface_index;
  uint32_t prefix_length;
  uint32_t address_v4;
  char interface_name[16];
} ForgeUsbMacNcmInterface;
#pragma pack(pop)

void ForgeUsbMacNcmInterfacesLinkAnchor(void);
uint32_t ForgeUsbMacNcmInterfacesEnumerate(ForgeUsbMacNcmInterface *out, uint32_t capacity);

#endif
