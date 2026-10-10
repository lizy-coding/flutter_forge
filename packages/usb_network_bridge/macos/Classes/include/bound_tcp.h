#ifndef FORGE_USB_MAC_BOUND_TCP_H
#define FORGE_USB_MAC_BOUND_TCP_H

#include <stdint.h>

void ForgeUsbMacBoundTcpLinkAnchor(void);
void *ForgeUsbMacBoundTcpOpen(const char *interface_name, uint32_t interface_index,
                            const char *source, const char *target, uint16_t port,
                            const uint8_t *token, uint16_t *local_port, int32_t *error);
int32_t ForgeUsbMacBoundTcpStatus(void *handle);
void ForgeUsbMacBoundTcpClose(void *handle);

#endif
