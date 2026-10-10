// USB NCM / Wi-Fi network-interface enumeration for device discovery.
//
// This replaces a per-launch PowerShell subprocess (Get-NetAdapter piped
// through Get-PnpDeviceProperty) that EDR/antivirus flagged as a hidden,
// base64-obfuscated PowerShell invocation. The same data is produced here with
// documented Win32 APIs (GetAdaptersAddresses + GetIfEntry2 + SetupAPI), so the
// host never spawns a shell at startup.

#include <winsock2.h>
#include <ws2ipdef.h>
#include <iphlpapi.h>
#include <setupapi.h>
#include <windows.h>

#include <cstdint>
#include <cstring>
#include <string>
#include <unordered_set>
#include <vector>

// Byte layout (packed, record size 222) as read by the Dart FFI layer:
//   +0   uint32 interfaceIndex
//   +4   uint32 kind (0 unknown, 1 wifi, 2 usbNcm)
//   +8   uint32 prefixLength (bits)
//   +12  uint32 addressV4 (network byte order; octets in memory order)
//   +16  wchar_t[39] guid   (UTF-16, lowercase hyphenated, no braces)
//   +94  wchar_t[64] name   (UTF-16 display name)
// Fixed-layout record shared with the Dart FFI layer. wchar_t is UTF-16 on
// Windows (pluggable C++ uses the MSVC ABI), so Dart reads it via
// readUtf16String. Keep every field width in sync with net_interfaces.dart.
#pragma pack(push, 1)
struct ForgeUsbNetInterfaceRecord {
  uint32_t interfaceIndex;   // ifIndex / MIB_IF_ROW2.InterfaceIndex
  uint32_t kind;             // 0 unknown, 1 wifi, 2 usbNcm
  uint32_t prefixLength;     // IPv4 on-link prefix length in bits
  uint32_t addressV4;        // IPv4 in network byte order (octets in memory order)
  wchar_t guid[39];          // Interface GUID, lowercase hyphenated, no braces, null-terminated
  wchar_t name[64];          // FriendlyName (display only), null-terminated
};
#pragma pack(pop)

namespace {

constexpr uint32_t kKindUnknown = 0;
constexpr uint32_t kKindWifi = 1;
constexpr uint32_t kKindUsbNcm = 2;

// GUID_DEVCLASS_NET = {4d36e972-e325-11ce-bfc1-08002be10318}.
constexpr GUID kNetDeviceClass = {
    0x4d36e972, 0xe325, 0x11ce, {0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18}};

wchar_t LowerAscii(wchar_t c) {
  if (c >= L'A' && c <= L'Z') return static_cast<wchar_t>(c + (L'a' - L'A'));
  return c;
}

bool EqualsIgnoreCase(const wchar_t* a, const wchar_t* b) {
  for (; *a && *b; ++a, ++b) {
    if (LowerAscii(*a) != LowerAscii(*b)) return false;
  }
  return *a == L'\0' && *b == L'\0';
}

// Case-insensitive "starts with" for a single UTF-16 needle.
bool StartsWithIgnoreCase(const std::wstring& haystack, const wchar_t* needle) {
  if (haystack.size() < wcslen(needle)) return false;
  for (size_t i = 0; needle[i] != L'\0'; ++i) {
    if (LowerAscii(haystack[i]) != LowerAscii(needle[i])) return false;
  }
  return true;
}

void CopyTruncated(wchar_t* dst, size_t dstCount, const wchar_t* src) {
  size_t i = 0;
  for (; i + 1 < dstCount && src[i] != L'\0'; ++i) dst[i] = src[i];
  dst[i] = L'\0';
}

// Copy an ASCII adapter GUID, dropping braces and lowercasing to match the
// System.Guid.ToString() form the legacy script produced. Writes into a wchar
// buffer of dstCount elements.
void CopyGuidNoBracesAscii(const char* adapterName, wchar_t* dst, size_t dstCount) {
  size_t out = 0;
  for (const char* p = adapterName; *p != '\0' && out + 1 < dstCount; ++p) {
    if (*p == '{' || *p == '}') continue;
    dst[out++] = LowerAscii(static_cast<wchar_t>(static_cast<unsigned char>(*p)));
  }
  dst[out] = L'\0';
}

// Same normalization into a std::wstring for hash-set lookups.
std::wstring NormalizedGuidAscii(const char* adapterName) {
  std::wstring lowered;
  for (const char* p = adapterName; *p != '\0'; ++p) {
    if (*p == '{' || *p == '}') continue;
    lowered.push_back(LowerAscii(static_cast<wchar_t>(static_cast<unsigned char>(*p))));
  }
  return lowered;
}

std::wstring NormalizedGuidWide(const wchar_t* value) {
  std::wstring lowered;
  for (const wchar_t* p = value; *p != L'\0'; ++p) {
    if (*p == L'{' || *p == L'}') continue;
    lowered.push_back(LowerAscii(*p));
  }
  return lowered;
}

// Read a device registry property (REG_SZ / REG_MULTI_SZ) into 'out',
// querying the required buffer size first so long compatible-id lists are never
// silently truncated. Returns false only when the property is absent/unreadable.
bool GetDevicePropertyWide(HDEVINFO info, PSP_DEVINFO_DATA data, DWORD propId,
                          std::vector<WCHAR>& out) {
  out.clear();
  DWORD required = 0;
  DWORD regType = 0;
  SetupDiGetDeviceRegistryPropertyW(info, data, propId, &regType, nullptr, 0, &required);
  const DWORD err = GetLastError();
  if (required == 0 && err != ERROR_INSUFFICIENT_BUFFER) return false;
  const size_t wcharCount = (required + sizeof(WCHAR) - 1) / sizeof(WCHAR);
  out.assign(wcharCount + 2, L'\0');
  if (!SetupDiGetDeviceRegistryPropertyW(info, data, propId, &regType,
                                         reinterpret_cast<PBYTE>(out.data()),
                                         static_cast<DWORD>(out.size() * sizeof(WCHAR)),
                                         nullptr)) {
    return false;
  }
  out[out.size() - 1] = L'\0';
  return true;
}

// Adapter GUIDs (lowercase, no braces) whose matching PnP device is a Windows
// CDC-NCM network adapter. Mirrors the PowerShell predicate:
//   Service == 'UsbNcm' AND CompatibleIds ~ '^USB\Class_02&SubClass_0d' OR '^USB\MS_COMP_WINNCM'
std::unordered_set<std::wstring> CollectNcmGuids() {
  std::unordered_set<std::wstring> result;
  HDEVINFO info = SetupDiGetClassDevsW(&kNetDeviceClass, nullptr, nullptr, DIGCF_PRESENT);
  if (info == INVALID_HANDLE_VALUE) return result;

  for (DWORD member = 0;; ++member) {
    SP_DEVINFO_DATA data{};
    data.cbSize = sizeof(data);
    if (!SetupDiEnumDeviceInfo(info, member, &data)) break;

    std::vector<WCHAR> service;
    if (!GetDevicePropertyWide(info, &data, SPDRP_SERVICE, service)) continue;
    if (!EqualsIgnoreCase(service.data(), L"UsbNcm")) continue;

    // CompatibleIds is a REG_MULTI_SZ; the original used an anchored regex on
    // any element, so check each id against both prefixes. Read it through the
    // size-safe helper so a long list is never truncated (a truncated buffer that
    // drops the MS_COMP_WINNCM entry made the adapter fall through to kind=unknown,
    // surfacing as an unknown-network status in the host.
    std::vector<WCHAR> compat;
    if (!GetDevicePropertyWide(info, &data, SPDRP_COMPATIBLEIDS, compat)) continue;
    bool matched = false;
    const WCHAR* id = compat.data();
    while (*id != L'\0') {
      std::wstring current(id);
      if (StartsWithIgnoreCase(current, L"USB\\Class_02&SubClass_0D") ||
          StartsWithIgnoreCase(current, L"USB\\MS_COMP_WINNCM")) {
        matched = true;
        break;
      }
      id += current.size() + 1;
    }
    if (!matched) continue;

    // NetCfgInstanceId under the device key equals the adapter InterfaceGuid.
    HKEY key = SetupDiOpenDevRegKey(info, &data, DICS_FLAG_GLOBAL, 0, DIREG_DEV, KEY_READ);
    if (key == INVALID_HANDLE_VALUE) continue;
    WCHAR netCfg[64] = {};
    DWORD valueBytes = sizeof(netCfg);
    DWORD valueType = 0;
    if (RegQueryValueExW(key, L"NetCfgInstanceId", nullptr, &valueType,
                         reinterpret_cast<PBYTE>(netCfg), &valueBytes) == ERROR_SUCCESS) {
      std::wstring guid = NormalizedGuidWide(netCfg);
      if (!guid.empty()) result.insert(guid);
    }
    RegCloseKey(key);
  }
  SetupDiDestroyDeviceInfoList(info);
  return result;
}

bool IsWifiMedium(uint32_t physicalMedium) {
  // NDIS_PHYSICAL_MEDIUM: 1 = WirelessLan, 9 = Native802_11. Matches the
  // legacy "NdisPhysicalMedium -eq 9 -or -eq 1" test exactly.
  return physicalMedium == 1u || physicalMedium == 9u;
}

}  // namespace

// Fill out with up to outCount records; return the number written, or the
// number that would be written when out is null. Returns (uint32_t)-1 on a
// fatal enumeration failure so the caller can fall back to an empty snapshot.
extern "C" __declspec(dllexport) uint32_t ForgeUsbNetInterfacesEnumerate(
    ForgeUsbNetInterfaceRecord* out, uint32_t outCount) {
  const std::unordered_set<std::wstring> ncmGuids = CollectNcmGuids();

  ULONG flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST | GAA_FLAG_SKIP_DNS_SERVER;
  ULONG size = 0;
  std::vector<unsigned char> buffer;
  ULONG rc = GetAdaptersAddresses(AF_UNSPEC, flags, nullptr, nullptr, &size);
  if (rc != ERROR_SUCCESS && rc != ERROR_BUFFER_OVERFLOW) return static_cast<uint32_t>(-1);
  buffer.resize(size);
  rc = GetAdaptersAddresses(AF_UNSPEC, flags, nullptr,
                            reinterpret_cast<IP_ADAPTER_ADDRESSES*>(buffer.data()), &size);
  if (rc != NO_ERROR) return static_cast<uint32_t>(-1);

  uint32_t needed = 0;
  for (const IP_ADAPTER_ADDRESSES* adapter =
           reinterpret_cast<const IP_ADAPTER_ADDRESSES*>(buffer.data());
       adapter != nullptr; adapter = adapter->Next) {
    if (adapter->OperStatus != IfOperStatusUp) continue;  // legacy "Status -eq Up".
    // Get-NetAdapter never lists the software loopback; drop it so the
    // snapshot contents match the legacy output exactly.
    if (adapter->IfType == IF_TYPE_SOFTWARE_LOOPBACK) continue;

    const std::wstring guid = NormalizedGuidAscii(adapter->AdapterName);
    uint32_t kind = kKindUnknown;
    if (ncmGuids.find(guid) != ncmGuids.end()) {
      kind = kKindUsbNcm;
    } else {
      MIB_IF_ROW2 row{};
      row.InterfaceIndex = adapter->IfIndex;
      if (GetIfEntry2(&row) == NO_ERROR &&
          IsWifiMedium(static_cast<uint32_t>(row.PhysicalMediumType))) {
        kind = kKindWifi;
      }
    }

    for (const IP_ADAPTER_UNICAST_ADDRESS_LH* unicast = adapter->FirstUnicastAddress;
         unicast != nullptr; unicast = unicast->Next) {
      if (unicast->Address.lpSockaddr == nullptr || unicast->Address.lpSockaddr->sa_family != AF_INET) continue;
      if (unicast->DadState != IpDadStatePreferred) continue;  // "AddressState -eq Preferred".
      if (unicast->OnLinkPrefixLength < 1 || unicast->OnLinkPrefixLength > 32) continue;

      const uint32_t index = needed;
      ++needed;
      if (out == nullptr || index >= outCount) continue;

      ForgeUsbNetInterfaceRecord& record = out[index];
      record = ForgeUsbNetInterfaceRecord{};
      record.interfaceIndex = adapter->IfIndex;
      record.kind = kind;
      record.prefixLength = unicast->OnLinkPrefixLength;
      record.addressV4 = reinterpret_cast<const sockaddr_in*>(unicast->Address.lpSockaddr)->sin_addr.s_addr;
      CopyGuidNoBracesAscii(adapter->AdapterName, record.guid, 39);
      CopyTruncated(record.name, 64, adapter->FriendlyName);
    }
  }
  return needed;
}
