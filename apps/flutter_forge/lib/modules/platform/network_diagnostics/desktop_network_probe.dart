import 'dart:async';
import 'dart:io';

import 'diagnostic_models.dart';
import 'network_probe.dart';

NetworkProbe createNetworkProbe() => DesktopNetworkProbe();

class DesktopNetworkProbe implements NetworkProbe {
  DesktopNetworkProbe({
    this.stageTimeout = const Duration(seconds: 3),
    Future<List<InternetAddress>> Function(String)? lookup,
  }) : _lookup = lookup ?? InternetAddress.lookup;
  final Duration stageTimeout;
  final Future<List<InternetAddress>> Function(String) _lookup;

  @override
  Future<NetworkSnapshot> snapshot(DiagnosticCancellation cancellation) async {
    List<NetworkInterface>? interfaces;
    try {
      interfaces = await cancellation.wait(
        NetworkInterface.list(includeLinkLocal: true),
        stageTimeout,
      );
    } on DiagnosticCancelled {
      rethrow;
    } catch (_) {
      // Keep DNS integrity probing available if interface enumeration fails.
    }
    final dns = await checkInvalidDns(cancellation);
    return NetworkSnapshot(
      system: Platform.operatingSystem,
      interfaces: [
        for (final item in interfaces ?? <NetworkInterface>[])
          '${item.name}: ${item.addresses.map((a) => a.address).join(', ')}',
      ],
      vpn: interfaces == null
          ? const DiagnosticCheck(
              'VPN／隧道',
              CheckLevel.unknown,
              '网卡信息不可用，无法判断 VPN 状态。',
            )
          : vpnInterfaceCheck(interfaces.map((i) => i.name)),
      dnsIntegrity: dns,
      note: '网卡地址不证明可以上网；Wi-Fi 名称、网关及系统代理未采集。',
    );
  }

  Future<DiagnosticCheck> checkInvalidDns(
    DiagnosticCancellation cancellation,
  ) async {
    try {
      // RFC 6761 §6.4 reserves .invalid; use an absolute, per-run name.
      final addresses = await cancellation.wait(
        _lookup('forge-${DateTime.now().microsecondsSinceEpoch}.invalid.'),
        stageTimeout,
      );
      return addresses.isEmpty
          ? const DiagnosticCheck(
              'DNS 劫持线索',
              CheckLevel.noSignal,
              '保留的 .invalid 名称未返回地址；不能排除其他域名被劫持或本机提前拒绝解析。',
            )
          : const DiagnosticCheck(
              'DNS 劫持线索',
              CheckLevel.suspicious,
              '.invalid 名称意外返回地址，可能涉及 DNS 改写、代理 Fake-IP 或本机配置；请核对 VPN、DNS 与认证网络。',
            );
    } on DiagnosticCancelled {
      rethrow;
    } catch (_) {
      // dart:io does not expose a portable DNS RCODE: failure is not NXDOMAIN proof.
      return const DiagnosticCheck(
        'DNS 劫持线索',
        CheckLevel.unknown,
        '.invalid 查询未返回结果；系统解析接口无法区分预期不存在、断网及解析器故障，不能据此排除劫持。',
      );
    }
  }

  @override
  Future<ProbeSample> probe(
    DiagnosticTarget target,
    int round,
    DiagnosticCancellation cancellation,
  ) async {
    final readings = <ProbeReading>[];
    final securityChecks = <DiagnosticCheck>[];
    Future<bool> measure(
      ProbeStage stage,
      Future<ProbeReading> Function(Stopwatch) action,
    ) async {
      cancellation.check();
      final watch = Stopwatch()..start();
      try {
        readings.add(await action(watch));
        return true;
      } on DiagnosticCancelled {
        rethrow;
      } catch (error) {
        cancellation.check();
        if (error is HandshakeException) {
          securityChecks.add(
            const DiagnosticCheck(
              'TLS 劫持线索',
              CheckLevel.suspicious,
              'TLS 握手或证书校验失败，可能涉及拦截，也可能是服务证书、系统时间或协议问题；未绕过校验。',
            ),
          );
        }
        readings.add(
          ProbeReading(
            stage: stage,
            outcome: ProbeOutcome.failure,
            elapsed: watch.elapsed,
            detail: switch (error) {
              TimeoutException() => '超时（${stageTimeout.inMilliseconds} ms 上限）',
              HandshakeException() => 'TLS 握手或证书校验失败；未绕过证书校验',
              SocketException() => '系统网络操作失败，可能涉及解析、拒绝连接或路由；不能据此确定根因',
              _ => '检测操作失败；未取得有效结果',
            },
          ),
        );
        return false;
      }
    }

    final resolved = await measure(ProbeStage.dns, (watch) async {
      final addresses = await cancellation.wait(
        _lookup(target.uri.host),
        stageTimeout,
      );
      if (addresses.isEmpty) throw const SocketException('No addresses');
      return ProbeReading(
        stage: ProbeStage.dns,
        outcome: ProbeOutcome.success,
        elapsed: watch.elapsed,
        detail: '系统解析得到 ${addresses.length} 个地址',
        addresses: [for (final a in addresses) a.address],
      );
    });
    final connected =
        resolved &&
        await measure(ProbeStage.tcp, (watch) async {
          ConnectionTask<Socket>? task;
          Socket? socket;
          var ended = false;
          void close() {
            task?.cancel();
            socket?.destroy();
          }

          final remove = cancellation.register(close);
          try {
            await cancellation.wait(() async {
              final started = await Socket.startConnect(
                target.uri.host,
                target.uri.port,
              );
              task = started;
              if (ended || cancellation.isCancelled) started.cancel();
              final opened = await started.socket;
              socket = opened;
              if (ended || cancellation.isCancelled) opened.destroy();
            }(), stageTimeout);
            cancellation.check();
            return ProbeReading(
              stage: ProbeStage.tcp,
              outcome: ProbeOutcome.success,
              elapsed: watch.elapsed,
              detail: '端口 ${target.uri.port} 已建立连接；不代表服务业务正常',
            );
          } finally {
            ended = true;
            close();
            remove();
          }
        });
    if (!resolved) {
      readings.add(
        const ProbeReading(
          stage: ProbeStage.tcp,
          outcome: ProbeOutcome.skipped,
          elapsed: Duration.zero,
          detail: '解析未成功，未执行连接',
        ),
      );
    }
    if (!target.isTcp) {
      if (connected) {
        await measure(ProbeStage.http, (watch) async {
          final client = HttpClient()..connectionTimeout = stageTimeout;
          client.findProxy = (_) => 'DIRECT';
          final remove = cancellation.register(() => client.close(force: true));
          try {
            final response = await cancellation.wait(() async {
              final request = await client.headUrl(target.uri);
              request.followRedirects = false;
              request.persistentConnection = false;
              return request.close();
            }(), stageTimeout);
            cancellation.check();
            securityChecks.addAll(
              httpSecurityChecks(
                target.uri,
                response.statusCode,
                response.headers.value(HttpHeaders.locationHeader),
              ),
            );
            return ProbeReading(
              stage: ProbeStage.http,
              outcome: ProbeOutcome.success,
              elapsed: watch.elapsed,
              statusCode: response.statusCode,
              detail: '收到 HTTP ${response.statusCode}；仅代表该服务已响应，不跟随重定向',
            );
          } finally {
            client.close(force: true);
            remove();
          }
        });
      } else {
        readings.add(
          const ProbeReading(
            stage: ProbeStage.http,
            outcome: ProbeOutcome.skipped,
            elapsed: Duration.zero,
            detail: '连接未成功，未执行请求',
          ),
        );
      }
    }
    return ProbeSample(
      target: target,
      round: round,
      readings: List.unmodifiable(readings),
      securityChecks: List.unmodifiable([
        ...securityChecks,
        if (securityChecks.isEmpty)
          const DiagnosticCheck(
            'HTTP／TLS 劫持线索',
            CheckLevel.unknown,
            '未取得可判断的 HTTP／TLS 证据；TCP 成功或普通连接失败不能证明是否被劫持。',
          ),
      ]),
    );
  }
}

DiagnosticCheck vpnInterfaceCheck(Iterable<String> names) {
  final pattern = RegExp(
    r'^(utun\d*|tun\d*|tap\d*|ppp\d*|wg\d*)$|wireguard|wintun|openvpn|tailscale|zerotier|vpn',
    caseSensitive: false,
  );
  final found = names.any((name) => pattern.hasMatch(name));
  return DiagnosticCheck(
    'VPN／隧道',
    found ? CheckLevel.notice : CheckLevel.unknown,
    found
        ? '发现疑似 VPN／隧道网卡；系统服务或虚拟网络也可能创建它，不能确认 VPN 已连接、默认路由或目标流量经过 VPN。'
        : '未发现常见 VPN／隧道网卡名称；不能排除使用其他名称、系统扩展或代理模式的 VPN。',
  );
}

List<DiagnosticCheck> httpSecurityChecks(
  Uri target,
  int status,
  String? location,
) {
  final checks = <DiagnosticCheck>[];
  if (target.scheme == 'https') {
    checks.add(
      const DiagnosticCheck(
        'TLS 劫持线索',
        CheckLevel.noSignal,
        '本次 HTTPS 通过系统信任链与主机名校验；无法排除系统信任的拦截证书或服务端异常。',
      ),
    );
  } else {
    checks.add(
      const DiagnosticCheck(
        'HTTP 劫持线索',
        CheckLevel.unknown,
        '明文 HTTP 无法验证响应身份；仅凭状态码不能排除内容改写或认证门户。',
      ),
    );
  }
  if ([301, 302, 303, 307, 308].contains(status)) {
    final redirect = location == null ? null : Uri.tryParse(location);
    final destination = redirect == null ? null : target.resolveUri(redirect);
    final downgrade = target.scheme == 'https' && destination?.scheme == 'http';
    checks.add(
      DiagnosticCheck(
        '重定向检查',
        downgrade ? CheckLevel.suspicious : CheckLevel.notice,
        downgrade
            ? '收到 HTTPS 降级到 HTTP 的跳转；请核对网站配置或网络拦截，未跟随跳转。'
            : destination == null
            ? '收到重定向但缺少有效跳转地址，无法判断；未跟随跳转。'
            : destination.host != target.host
            ? '收到跨主机跳转，可能是正常登录、站点迁移或认证门户；不能仅据此判定劫持，未跟随跳转。'
            : '收到同主机跳转，可能是正常网站行为；未跟随跳转，未验证最终页面。',
      ),
    );
  }
  return checks;
}
