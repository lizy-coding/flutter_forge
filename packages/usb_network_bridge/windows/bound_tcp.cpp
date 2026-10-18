// A per-connection loopback relay lets dart:io retain ownership of TLS/WS,
// while Winsock selects the IPv4 interface BEFORE connecting to the device.
#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>
#include <objbase.h>
#include <array>
#include <atomic>
#include <cstdint>
#include <cstring>
#include <new>

namespace {
struct SocketOwner {
  SOCKET value = INVALID_SOCKET;
  ~SocketOwner() { if (value != INVALID_SOCKET) closesocket(value); }
};
struct Relay {
  SocketOwner listener;
  HANDLE worker = nullptr;
  std::atomic<bool> stop{false};
  std::atomic<int> status{0};
  sockaddr_in source{};
  sockaddr_in target{};
  DWORD index = 0;
  std::array<char, 16> token{};
  ~Relay() {
    stop = true;
    if (worker) { WaitForSingleObject(worker, INFINITE); CloseHandle(worker); }
    if (listener.value != INVALID_SOCKET) {
      closesocket(listener.value); listener.value = INVALID_SOCKET;
    }
    WSACleanup();
  }
};
bool Nonblocking(SOCKET socket) {
  u_long on = 1;
  return ioctlsocket(socket, FIONBIO, &on) == 0;
}
bool Wait(Relay* relay, SOCKET socket, bool writing, ULONGLONG deadline) {
  while (!relay->stop && GetTickCount64() < deadline) {
    fd_set ready, errors;
    FD_ZERO(&ready); FD_SET(socket, &ready);
    FD_ZERO(&errors); FD_SET(socket, &errors);
    timeval timeout{0, 20000};
    int result = select(0, writing ? nullptr : &ready,
                        writing ? &ready : nullptr, &errors, &timeout);
    if (result == SOCKET_ERROR) return false;
    if (result > 0) return true;  // Caller checks SO_ERROR/recv/send.
  }
  WSASetLastError(relay->stop ? WSA_OPERATION_ABORTED : WSAETIMEDOUT);
  return false;
}
bool Authenticate(Relay* relay, SOCKET socket, ULONGLONG deadline) {
  std::array<char, 16> received{};
  int count = 0;
  while (count < static_cast<int>(received.size())) {
    if (!Wait(relay, socket, false, deadline)) return false;
    int n = recv(socket, received.data() + count,
                 static_cast<int>(received.size()) - count, 0);
    if (n == SOCKET_ERROR && WSAGetLastError() == WSAEWOULDBLOCK) continue;
    if (n <= 0) return false;
    count += n;
  }
  return received == relay->token;
}
struct Buffer {
  std::array<char, 65536> data{};
  int begin = 0;
  int end = 0;
  bool eof = false;
  bool shutdown = false;
};
bool Transfer(SOCKET from, SOCKET to, Buffer& buffer,
              const fd_set& reads, const fd_set& writes) {
  if (FD_ISSET(from, &reads)) {
    int n = recv(from, buffer.data.data(), static_cast<int>(buffer.data.size()), 0);
    if (n == 0) buffer.eof = true;
    else if (n > 0) { buffer.begin = 0; buffer.end = n; }
    else if (WSAGetLastError() != WSAEWOULDBLOCK) return false;
  }
  if (buffer.end > buffer.begin && FD_ISSET(to, &writes)) {
    int n = send(to, buffer.data.data() + buffer.begin,
                 buffer.end - buffer.begin, 0);
    if (n > 0) buffer.begin += n;
    else if (n == 0 || WSAGetLastError() != WSAEWOULDBLOCK) return false;
  }
  if (buffer.eof && buffer.begin == buffer.end && !buffer.shutdown) {
    shutdown(to, SD_SEND);
    buffer.shutdown = true;
  }
  return true;
}
DWORD WINAPI Run(void* context) {
  auto* relay = static_cast<Relay*>(context);
  SocketOwner local, remote;
  const auto deadline = GetTickCount64() + 5000;
  // An unpredictable token prevents another local process from taking this route.
  while (!relay->stop && GetTickCount64() < deadline) {
    if (!Wait(relay, relay->listener.value, false, deadline)) break;
    SOCKET accepted = accept(relay->listener.value, nullptr, nullptr);
    if (accepted == INVALID_SOCKET) continue;
    if (Nonblocking(accepted) && Authenticate(relay, accepted, deadline)) {
      local.value = accepted;
      break;
    }
    closesocket(accepted);
  }
  if (local.value == INVALID_SOCKET) {
    relay->status = -WSAETIMEDOUT;
    return 0;
  }
  remote.value = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  const DWORD index = htonl(relay->index);  // IP_UNICAST_IF uses network order.
  if (remote.value == INVALID_SOCKET ||
      setsockopt(remote.value, IPPROTO_IP, IP_UNICAST_IF,
                 reinterpret_cast<const char*>(&index), sizeof(index)) != 0 ||
      bind(remote.value, reinterpret_cast<const sockaddr*>(&relay->source),
           sizeof(relay->source)) != 0 || !Nonblocking(remote.value)) {
    relay->status = -WSAGetLastError();
    return 0;
  }
  if (connect(remote.value, reinterpret_cast<const sockaddr*>(&relay->target),
              sizeof(relay->target)) != 0) {
    int error = WSAGetLastError();
    if (error != WSAEWOULDBLOCK ||
        !Wait(relay, remote.value, true, GetTickCount64() + 5000)) {
      relay->status = -(error != WSAEWOULDBLOCK ? error : WSAGetLastError());
      return 0;
    }
    int length = sizeof(error);
    if (getsockopt(remote.value, SOL_SOCKET, SO_ERROR,
                   reinterpret_cast<char*>(&error), &length) != 0)
      error = WSAGetLastError();
    if (error != 0) { relay->status = -error; return 0; }
  }
  relay->status = 1;
  Buffer upstream, downstream;
  while (!relay->stop && !(upstream.shutdown && downstream.shutdown)) {
    fd_set reads, writes;
    FD_ZERO(&reads); FD_ZERO(&writes);
    if (!upstream.eof && upstream.begin == upstream.end) FD_SET(local.value, &reads);
    if (!downstream.eof && downstream.begin == downstream.end) FD_SET(remote.value, &reads);
    if (upstream.begin < upstream.end) FD_SET(remote.value, &writes);
    if (downstream.begin < downstream.end) FD_SET(local.value, &writes);
    timeval timeout{0, 20000};
    if (select(0, &reads, &writes, nullptr, &timeout) == SOCKET_ERROR ||
        !Transfer(local.value, remote.value, upstream, reads, writes) ||
        !Transfer(remote.value, local.value, downstream, reads, writes)) break;
  }
  return 0;
}
}  // namespace

extern "C" __declspec(dllexport) void* ForgeUsbBoundTcpOpen(
    const wchar_t* interface_guid, uint32_t interface_index,
    const char* source, const char* target, uint16_t port,
    const uint8_t* token, uint16_t* local_port, int32_t* error) {
  *error = WSAEINVAL;
  if (!interface_guid || !source || !target || !token || interface_index == 0 ||
      port == 0) return nullptr;
  WSADATA data{};
  int startup = WSAStartup(MAKEWORD(2, 2), &data);
  if (startup != 0) { *error = startup; return nullptr; }
  auto* relay = new (std::nothrow) Relay;
  if (!relay) { WSACleanup(); *error = WSA_NOT_ENOUGH_MEMORY; return nullptr; }
  relay->index = interface_index;
  relay->source.sin_family = AF_INET;
  relay->target.sin_family = AF_INET;
  relay->target.sin_port = htons(port);
  GUID guid{};
  MIB_IF_ROW2 adapter{};
  adapter.InterfaceIndex = interface_index;
  MIB_UNICASTIPADDRESS_ROW address{};
  InitializeUnicastIpAddressEntry(&address);
  address.InterfaceIndex = interface_index;
  address.Address.si_family = AF_INET;
  if (InetPtonA(AF_INET, source, &relay->source.sin_addr) != 1 ||
      InetPtonA(AF_INET, target, &relay->target.sin_addr) != 1 ||
      CLSIDFromString(interface_guid, &guid) != S_OK ||
      GetIfEntry2(&adapter) != NO_ERROR ||
      !IsEqualGUID(guid, adapter.InterfaceGuid) ||
      adapter.OperStatus != IfOperStatusUp) {
    delete relay; return nullptr;
  }
  address.Address.Ipv4.sin_addr = relay->source.sin_addr;
  if (GetUnicastIpAddressEntry(&address) != NO_ERROR ||
      address.DadState != IpDadStatePreferred ||
      relay->source.sin_addr.s_addr == relay->target.sin_addr.s_addr) {
    delete relay; return nullptr;
  }
  std::memcpy(relay->token.data(), token, relay->token.size());
  relay->listener.value = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  sockaddr_in local{};
  local.sin_family = AF_INET;
  local.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  BOOL exclusive = TRUE;
  if (relay->listener.value == INVALID_SOCKET ||
      setsockopt(relay->listener.value, SOL_SOCKET, SO_EXCLUSIVEADDRUSE,
                 reinterpret_cast<const char*>(&exclusive), sizeof(exclusive)) != 0 ||
      bind(relay->listener.value, reinterpret_cast<const sockaddr*>(&local),
           sizeof(local)) != 0 ||
      listen(relay->listener.value, 1) != 0 || !Nonblocking(relay->listener.value)) {
    *error = WSAGetLastError(); delete relay; return nullptr;
  }
  int length = sizeof(local);
  if (getsockname(relay->listener.value, reinterpret_cast<sockaddr*>(&local), &length) != 0) {
    *error = WSAGetLastError(); delete relay; return nullptr;
  }
  *local_port = ntohs(local.sin_port);
  relay->worker = CreateThread(nullptr, 0, Run, relay, 0, nullptr);
  if (!relay->worker) { *error = WSA_NOT_ENOUGH_MEMORY; delete relay; return nullptr; }
  *error = 0;
  return relay;
}
extern "C" __declspec(dllexport) int32_t ForgeUsbBoundTcpStatus(void* handle) {
  return static_cast<Relay*>(handle)->status.load();
}
extern "C" __declspec(dllexport) void ForgeUsbBoundTcpClose(void* handle) {
  delete static_cast<Relay*>(handle);
}
