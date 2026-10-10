#include "include/bound_tcp.h"
#include "include/ncm_interfaces.h"

#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <net/if.h>
#include <netinet/in.h>
#include <poll.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>

typedef struct {
  int listener;
  pthread_t thread;
  atomic_int stop;
  atomic_int status;
  uint32_t interface_index;
  struct sockaddr_in source;
  struct sockaddr_in target;
  uint8_t token[16];
} Relay;

typedef struct {
  char data[65536];
  size_t begin;
  size_t end;
  int eof;
  int shutdown_sent;
} Buffer;

__attribute__((visibility("default"))) void ForgeUsbMacBoundTcpLinkAnchor(void) {
  void *(* volatile open_fn)(const char *, uint32_t, const char *, const char *,
                             uint16_t, const uint8_t *, uint16_t *, int32_t *) =
      ForgeUsbMacBoundTcpOpen;
  int32_t (* volatile status_fn)(void *) = ForgeUsbMacBoundTcpStatus;
  void (* volatile close_fn)(void *) = ForgeUsbMacBoundTcpClose;
  (void)open_fn;
  (void)status_fn;
  (void)close_fn;
}

static long now_ms(void) {
  struct timeval time;
  gettimeofday(&time, NULL);
  return (long)time.tv_sec * 1000 + time.tv_usec / 1000;
}

static int nonblocking(int fd) {
  int flags = fcntl(fd, F_GETFL);
  return flags >= 0 && fcntl(fd, F_SETFL, flags | O_NONBLOCK) == 0;
}

static int wait_for(Relay *relay, int fd, short events, long deadline) {
  while (!atomic_load(&relay->stop) && now_ms() < deadline) {
    struct pollfd pfd = {.fd = fd, .events = events};
    int rc = poll(&pfd, 1, 20);
    if (rc > 0) return 1;
    if (rc < 0 && errno != EINTR) return 0;
  }
  errno = atomic_load(&relay->stop) ? ECANCELED : ETIMEDOUT;
  return 0;
}

static int authenticate(Relay *relay, int fd, long deadline) {
  uint8_t received[16];
  size_t used = 0;
  while (used < sizeof(received)) {
    if (!wait_for(relay, fd, POLLIN, deadline)) return 0;
    ssize_t count = recv(fd, received + used, sizeof(received) - used, 0);
    if (count > 0) used += (size_t)count;
    else if (count == 0) return 0;
    else if (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) return 0;
  }
  return memcmp(received, relay->token, sizeof(received)) == 0;
}

static int transfer(int from, int to, Buffer *buffer, short from_events, short to_events) {
  if ((from_events & (POLLIN | POLLHUP)) && !buffer->eof && buffer->begin == buffer->end) {
    ssize_t count = recv(from, buffer->data, sizeof(buffer->data), 0);
    if (count > 0) {
      buffer->begin = 0;
      buffer->end = (size_t)count;
    } else if (count == 0) {
      buffer->eof = 1;
    } else if (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) {
      return 0;
    }
  }
  if ((to_events & POLLOUT) && buffer->begin < buffer->end) {
    ssize_t count = send(to, buffer->data + buffer->begin, buffer->end - buffer->begin, 0);
    if (count > 0) buffer->begin += (size_t)count;
    else if (count == 0 || (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR)) return 0;
  }
  if (buffer->eof && buffer->begin == buffer->end && !buffer->shutdown_sent) {
    shutdown(to, SHUT_WR);
    buffer->shutdown_sent = 1;
  }
  return 1;
}

static void *run(void *context) {
  Relay *relay = context;
  int local = -1;
  int remote = -1;
  long deadline = now_ms() + 5000;
  while (!atomic_load(&relay->stop) && now_ms() < deadline) {
    if (!wait_for(relay, relay->listener, POLLIN, deadline)) break;
    int candidate = accept(relay->listener, NULL, NULL);
    if (candidate < 0) {
      if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) continue;
      break;
    }
    int no_sigpipe = 1;
    if (setsockopt(candidate, SOL_SOCKET, SO_NOSIGPIPE, &no_sigpipe, sizeof(no_sigpipe)) == 0 &&
        nonblocking(candidate) && authenticate(relay, candidate, deadline)) {
      local = candidate;
      break;
    }
    close(candidate);
  }
  if (local < 0) goto failed;

  remote = socket(AF_INET, SOCK_STREAM, 0);
  if (remote < 0) goto failed;
  int no_sigpipe = 1;
  if (setsockopt(remote, SOL_SOCKET, SO_NOSIGPIPE, &no_sigpipe, sizeof(no_sigpipe)) != 0) goto failed;
  if (setsockopt(remote, IPPROTO_IP, IP_BOUND_IF, &relay->interface_index,
                 sizeof(relay->interface_index)) != 0 ||
      bind(remote, (struct sockaddr *)&relay->source, sizeof(relay->source)) != 0 ||
      !nonblocking(remote)) goto failed;
  if (connect(remote, (struct sockaddr *)&relay->target, sizeof(relay->target)) != 0) {
    if (errno != EINPROGRESS || !wait_for(relay, remote, POLLOUT, now_ms() + 5000)) goto failed;
    int connect_error = 0;
    socklen_t length = sizeof(connect_error);
    if (getsockopt(remote, SOL_SOCKET, SO_ERROR, &connect_error, &length) != 0) goto failed;
    if (connect_error != 0) {
      errno = connect_error;
      goto failed;
    }
  }
  atomic_store(&relay->status, 1);
  Buffer upstream = {0}, downstream = {0};
  while (!atomic_load(&relay->stop) && !(upstream.shutdown_sent && downstream.shutdown_sent)) {
    struct pollfd fds[2] = {
      {.fd = local, .events = (short)((!upstream.eof && upstream.begin == upstream.end ? POLLIN : 0) |
                                       (downstream.begin < downstream.end ? POLLOUT : 0))},
      {.fd = remote, .events = (short)((!downstream.eof && downstream.begin == downstream.end ? POLLIN : 0) |
                                        (upstream.begin < upstream.end ? POLLOUT : 0))},
    };
    int rc = poll(fds, 2, 20);
    if (rc < 0) {
      if (errno == EINTR) continue;
      break;
    }
    if ((fds[0].revents | fds[1].revents) & (POLLERR | POLLNVAL)) break;
    if (!transfer(local, remote, &upstream, fds[0].revents, fds[1].revents) ||
        !transfer(remote, local, &downstream, fds[1].revents, fds[0].revents)) break;
  }
  goto done;

failed:
  if (atomic_load(&relay->status) == 0) atomic_store(&relay->status, -(errno ? errno : EIO));
done:
  if (remote >= 0) close(remote);
  if (local >= 0) close(local);
  return NULL;
}

static int valid_interface(const char *name, uint32_t index, uint32_t source) {
  if (if_nametoindex(name) != index) return 0;
  uint32_t count = ForgeUsbMacNcmInterfacesEnumerate(NULL, 0);
  if (count == 0 || count == UINT32_MAX || count > 1024) return 0;
  ForgeUsbMacNcmInterface *records = calloc(count, sizeof(*records));
  if (records == NULL) return 0;
  uint32_t written = ForgeUsbMacNcmInterfacesEnumerate(records, count);
  int valid = 0;
  if (written <= count) {
    for (uint32_t i = 0; i < written; ++i) {
      if (records[i].interface_index == index && records[i].address_v4 == source &&
          strcmp(records[i].interface_name, name) == 0) {
        valid = 1;
        break;
      }
    }
  }
  free(records);
  return valid;
}

__attribute__((visibility("default"))) void *ForgeUsbMacBoundTcpOpen(
    const char *interface_name, uint32_t interface_index, const char *source,
    const char *target, uint16_t port, const uint8_t *token,
    uint16_t *local_port, int32_t *error) {
  if (error == NULL) return NULL;
  *error = EINVAL;
  if (interface_name == NULL || source == NULL || target == NULL || token == NULL ||
      local_port == NULL || interface_index == 0 || port == 0) return NULL;
  Relay *relay = calloc(1, sizeof(*relay));
  if (relay == NULL) {
    *error = ENOMEM;
    return NULL;
  }
  relay->listener = -1;
  relay->interface_index = interface_index;
  relay->source.sin_len = sizeof(relay->source);
  relay->source.sin_family = AF_INET;
  relay->target.sin_len = sizeof(relay->target);
  relay->target.sin_family = AF_INET;
  relay->target.sin_port = htons(port);
  if (inet_pton(AF_INET, source, &relay->source.sin_addr) != 1 ||
      inet_pton(AF_INET, target, &relay->target.sin_addr) != 1 ||
      relay->source.sin_addr.s_addr == relay->target.sin_addr.s_addr ||
      !valid_interface(interface_name, interface_index, relay->source.sin_addr.s_addr)) goto failed;
  memcpy(relay->token, token, sizeof(relay->token));
  relay->listener = socket(AF_INET, SOCK_STREAM, 0);
  if (relay->listener < 0) goto failed;
  int no_sigpipe = 1;
  setsockopt(relay->listener, SOL_SOCKET, SO_NOSIGPIPE, &no_sigpipe, sizeof(no_sigpipe));
  struct sockaddr_in loopback = {0};
  loopback.sin_len = sizeof(loopback);
  loopback.sin_family = AF_INET;
  loopback.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  if (bind(relay->listener, (struct sockaddr *)&loopback, sizeof(loopback)) != 0 ||
      listen(relay->listener, 1) != 0 || !nonblocking(relay->listener)) goto failed;
  socklen_t length = sizeof(loopback);
  if (getsockname(relay->listener, (struct sockaddr *)&loopback, &length) != 0) goto failed;
  *local_port = ntohs(loopback.sin_port);
  int thread_error = pthread_create(&relay->thread, NULL, run, relay);
  if (thread_error != 0) {
    errno = thread_error;
    goto failed;
  }
  *error = 0;
  return relay;
failed:
  *error = errno ? errno : EINVAL;
  if (relay->listener >= 0) close(relay->listener);
  free(relay);
  return NULL;
}

__attribute__((visibility("default"))) int32_t ForgeUsbMacBoundTcpStatus(void *handle) {
  return atomic_load(&((Relay *)handle)->status);
}

__attribute__((visibility("default"))) void ForgeUsbMacBoundTcpClose(void *handle) {
  if (handle == NULL) return;
  Relay *relay = handle;
  atomic_store(&relay->stop, 1);
  shutdown(relay->listener, SHUT_RDWR);
  pthread_join(relay->thread, NULL);
  close(relay->listener);
  free(relay);
}
