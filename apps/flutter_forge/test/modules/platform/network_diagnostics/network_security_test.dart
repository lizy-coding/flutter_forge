import 'dart:async';
import 'dart:io';

import 'package:flutter_forge_app/modules/platform/network_diagnostics/desktop_network_probe.dart';
import 'package:flutter_forge_app/modules/platform/network_diagnostics/diagnostic_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tunnel evidence never asserts an active VPN or absence of VPN', () {
    for (final name in [
      'utun4',
      'tun0',
      'wg0',
      'WireGuard Tunnel',
      'OpenVPN',
    ]) {
      final check = vpnInterfaceCheck([name]);
      expect(check.level, CheckLevel.notice);
      expect(check.detail, contains('不能确认 VPN 已连接'));
      expect(check.text, isNot(contains(name)));
    }
    expect(vpnInterfaceCheck(['en0', 'Ethernet']).level, CheckLevel.unknown);
  });

  test(
    'positive .invalid resolution is suspicious without leaking addresses',
    () async {
      final cancellation = DiagnosticCancellation();
      addTearDown(cancellation.cancel);
      final check = await DesktopNetworkProbe(
        lookup: (host) async {
          expect(host, matches(r'^forge-\d+\.invalid\.$'));
          return [InternetAddress('10.99.8.7')];
        },
      ).checkInvalidDns(cancellation);
      expect(check.level, CheckLevel.suspicious);
      expect(check.text, isNot(contains('10.99.8.7')));
    },
  );

  test(
    'DNS errors and timeouts cannot prove NXDOMAIN or no hijacking',
    () async {
      for (final lookup in <Future<List<InternetAddress>> Function(String)>[
        (_) => Future.error(const SocketException('offline')),
        (_) => Completer<List<InternetAddress>>().future,
      ]) {
        final cancellation = DiagnosticCancellation();
        addTearDown(cancellation.cancel);
        final check = await DesktopNetworkProbe(
          stageTimeout: const Duration(milliseconds: 20),
          lookup: lookup,
        ).checkInvalidDns(cancellation);
        expect(check.level, CheckLevel.unknown);
      }
    },
  );

  test('DNS integrity check obeys cancellation', () async {
    final cancellation = DiagnosticCancellation();
    final result = DesktopNetworkProbe(
      lookup: (_) => Completer<List<InternetAddress>>().future,
    ).checkInvalidDns(cancellation);
    final expectation = expectLater(
      result,
      throwsA(isA<DiagnosticCancelled>()),
    );
    cancellation.cancel();
    await expectation;
  });

  test(
    'normal cross-host redirects are notices; HTTPS downgrade is suspicious',
    () {
      final target = Uri.parse('https://example.com');
      final normal = httpSecurityChecks(
        target,
        302,
        'https://login.example.net/?token=secret',
      );
      expect(normal.first.level, CheckLevel.noSignal);
      expect(normal.last.level, CheckLevel.notice);
      expect(normal.last.text, isNot(contains('secret')));
      expect(
        httpSecurityChecks(target, 301, 'http://example.com').last.level,
        CheckLevel.suspicious,
      );
      expect(
        httpSecurityChecks(target, 302, '/home').last.level,
        CheckLevel.notice,
      );
      expect(httpSecurityChecks(target, 302, null).last.text, contains('缺少有效'));
      expect(
        httpSecurityChecks(
          Uri.parse('http://example.com'),
          200,
          null,
        ).single.level,
        CheckLevel.unknown,
      );
    },
  );

  test(
    'real TLS handshake failure supplies a clue without bypassing validation',
    () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((socket) {
        socket.add('HTTP/1.1 400 Bad Request\r\n\r\n'.codeUnits);
        unawaited(socket.flush().whenComplete(socket.destroy));
      });
      final cancellation = DiagnosticCancellation();
      addTearDown(cancellation.cancel);
      final result = await DesktopNetworkProbe().probe(
        DiagnosticTarget(Uri.parse('https://127.0.0.1:${server.port}')),
        1,
        cancellation,
      );
      expect(result.reached, isFalse);
      expect(result.securityChecks.single.level, CheckLevel.suspicious);
      expect(result.securityChecks.single.text, contains('未绕过校验'));
    },
  );
}
