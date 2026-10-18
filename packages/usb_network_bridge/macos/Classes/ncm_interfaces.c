#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netinet/in.h>
#include <stdint.h>
#include <string.h>

#include "include/ncm_interfaces.h"
__attribute__((visibility("default"))) void ForgeUsbMacNcmInterfacesLinkAnchor(void) {
  uint32_t (* volatile enumerate_fn)(ForgeUsbMacNcmInterface *, uint32_t) =
      ForgeUsbMacNcmInterfacesEnumerate;
  (void)enumerate_fn;
}

static io_registry_entry_t usb_device_for(io_registry_entry_t entry) {
  io_registry_entry_t current = entry;
  IOObjectRetain(current);
  while (current != MACH_PORT_NULL) {
    if (IOObjectConformsTo(current, "IOUSBHostDevice")) return current;
    io_registry_entry_t parent = MACH_PORT_NULL;
    if (IORegistryEntryGetParentEntry(current, kIOServicePlane, &parent) != KERN_SUCCESS) break;
    IOObjectRelease(current);
    current = parent;
  }
  if (current != MACH_PORT_NULL) IOObjectRelease(current);
  return MACH_PORT_NULL;
}

static uint64_t registry_id(io_registry_entry_t entry) {
  uint64_t value = 0;
  IORegistryEntryGetRegistryEntryID(entry, &value);
  return value;
}

static int number_property(io_registry_entry_t entry, CFStringRef key, int expected) {
  CFTypeRef property = IORegistryEntryCreateCFProperty(entry, key, kCFAllocatorDefault, 0);
  if (property == NULL || CFGetTypeID(property) != CFNumberGetTypeID()) {
    if (property != NULL) CFRelease(property);
    return 0;
  }
  int value = 0;
  int matches = CFNumberGetValue((CFNumberRef)property, kCFNumberIntType, &value) && value == expected;
  CFRelease(property);
  return matches;
}

static int has_ncm_interface(uint64_t device_id) {
  CFMutableDictionaryRef matching = IOServiceMatching("IOUSBHostInterface");
  if (matching == NULL) return 0;
  io_iterator_t iterator = MACH_PORT_NULL;
  if (IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) != KERN_SUCCESS) return 0;
  int found = 0;
  io_registry_entry_t interface = MACH_PORT_NULL;
  while ((interface = IOIteratorNext(iterator)) != MACH_PORT_NULL) {
    io_registry_entry_t device = usb_device_for(interface);
    if (device != MACH_PORT_NULL) {
      if (registry_id(device) == device_id &&
          number_property(interface, CFSTR("bInterfaceClass"), 2) &&
          number_property(interface, CFSTR("bInterfaceSubClass"), 0x0d)) found = 1;
      IOObjectRelease(device);
    }
    IOObjectRelease(interface);
    if (found) break;
  }
  IOObjectRelease(iterator);
  return found;
}

static int prefix_length(uint32_t netmask) {
  uint32_t mask = ntohl(netmask);
  int count = 0;
  int zero_seen = 0;
  for (int bit = 31; bit >= 0; --bit) {
    int set = (mask >> bit) & 1;
    if (!set) zero_seen = 1;
    else if (zero_seen) return 0;
    else ++count;
  }
  return count;
}

static int enumerate(ForgeUsbMacNcmInterface *out, uint32_t capacity) {
  struct ifaddrs *addresses = NULL;
  if (getifaddrs(&addresses) != 0) return -1;
  uint32_t count = 0;
  for (struct ifaddrs *address = addresses; address != NULL; address = address->ifa_next) {
    if (address->ifa_addr == NULL || address->ifa_addr->sa_family != AF_INET ||
        (address->ifa_flags & IFF_UP) == 0 || (address->ifa_flags & IFF_LOOPBACK) != 0) continue;
    unsigned int index = if_nametoindex(address->ifa_name);
    if (index == 0) continue;
    io_iterator_t iterator = MACH_PORT_NULL;
    CFMutableDictionaryRef matching = IOServiceMatching("IOEthernetInterface");
    if (matching == NULL || IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) != KERN_SUCCESS) continue;
    int matches_ncm = 0;
    io_registry_entry_t ethernet = MACH_PORT_NULL;
    while ((ethernet = IOIteratorNext(iterator)) != MACH_PORT_NULL) {
      CFTypeRef name = IORegistryEntryCreateCFProperty(ethernet, CFSTR("BSD Name"), kCFAllocatorDefault, 0);
      char bsd_name[IFNAMSIZ] = {0};
      if (name != NULL && CFGetTypeID(name) == CFStringGetTypeID()) {
        CFStringGetCString((CFStringRef)name, bsd_name, sizeof(bsd_name), kCFStringEncodingUTF8);
      }
      if (name != NULL) CFRelease(name);
      if (strcmp(bsd_name, address->ifa_name) == 0) {
        io_registry_entry_t device = usb_device_for(ethernet);
        if (device != MACH_PORT_NULL) {
          matches_ncm = has_ncm_interface(registry_id(device));
          IOObjectRelease(device);
        }
        IOObjectRelease(ethernet);
        break;
      }
      IOObjectRelease(ethernet);
    }
    IOObjectRelease(iterator);
    if (!matches_ncm) continue;
    int prefix = address->ifa_netmask != NULL && address->ifa_netmask->sa_family == AF_INET
        ? prefix_length(((struct sockaddr_in *)address->ifa_netmask)->sin_addr.s_addr) : 0;
    if (prefix == 0) continue;
    if (out != NULL && count < capacity) {
      ForgeUsbMacNcmInterface *record = &out[count];
      memset(record, 0, sizeof(*record));
      record->interface_index = index;
      record->prefix_length = (uint32_t)prefix;
      record->address_v4 = ((struct sockaddr_in *)address->ifa_addr)->sin_addr.s_addr;
      strlcpy(record->interface_name, address->ifa_name, sizeof(record->interface_name));
    }
    ++count;
  }
  freeifaddrs(addresses);
  return (int)count;
}

__attribute__((visibility("default"))) uint32_t ForgeUsbMacNcmInterfacesEnumerate(
    ForgeUsbMacNcmInterface *out, uint32_t capacity) {
  int count = enumerate(out, capacity);
  return count < 0 ? UINT32_MAX : (uint32_t)count;
}
