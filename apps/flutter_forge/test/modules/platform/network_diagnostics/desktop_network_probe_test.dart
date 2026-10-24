import 'dart:async';
import 'dart:io';

import 'package:flutter_forge_app/modules/platform/network_diagnostics/desktop_network_probe.dart';
import 'package:flutter_forge_app/modules/platform/network_diagnostics/diagnostic_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'real local HTTP HEAD reports a 503 response and does not follow a redirect',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requests = <String>[];
      server.listen((request) {
        requests.add('${request.method} ${request.uri.path}');
        request.response.statusCode = request.uri.path == '/redirect'
            ? 302
            : 503;
        request.response.headers.set('location', '/landing');
        unawaited(request.response.close());
      });
      final probe = DesktopNetworkProbe();
      final cancellation = DiagnosticCancellation();
      addTearDown(cancellation.cancel);
      for (final path in ['/error', '/redirect']) {
        final target = DiagnosticTarget.parseLines(
          'http://127.0.0.1:${server.port}$path',
        ).single;
        final result = await probe.probe(target, 1, cancellation);
        expect(result.reached, isTrue);
        expect(result.readings.map((r) => r.stage), ProbeStage.values);
        expect(result.readings.last.statusCode, path == '/error' ? 503 : 302);
        expect(result.applicationWarning, path == '/error');
      }
      expect(requests, ['HEAD /error', 'HEAD /redirect']);
    },
  );

  test(
    'real local TCP target stops after connect and HTTP refusal is not needed',
    () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((socket) => socket.destroy());
      final target = DiagnosticTarget.parseLines(
        'tcp://127.0.0.1:${server.port}',
      ).single;
      final cancellation = DiagnosticCancellation();
      addTearDown(cancellation.cancel);
      final result = await DesktopNetworkProbe().probe(target, 1, cancellation);
      expect(result.reached, isTrue);
      expect(result.readings.length, 2);
      expect(result.readings.last.stage, ProbeStage.tcp);
    },
  );

  test(
    'HTTP stage timeout closes the connection and records bounded failure',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) {});
      final cancellation = DiagnosticCancellation();
      addTearDown(cancellation.cancel);
      final target = DiagnosticTarget.parseLines(
        'http://127.0.0.1:${server.port}',
      ).single;
      final result = await DesktopNetworkProbe(
        stageTimeout: const Duration(milliseconds: 200),
      ).probe(target, 1, cancellation);
      expect(result.reached, isFalse);
      expect(result.readings.last.stage, ProbeStage.http);
      expect(result.readings.last.detail, contains('超时'));
    },
  );

  test('cancellation interrupts a pending real HTTP request', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final received = Completer<void>();
    server.listen((request) => received.complete());
    final cancellation = DiagnosticCancellation();
    final target = DiagnosticTarget.parseLines(
      'http://127.0.0.1:${server.port}',
    ).single;
    final result = DesktopNetworkProbe().probe(target, 1, cancellation);
    final expectation = expectLater(
      result,
      throwsA(isA<DiagnosticCancelled>()),
    );
    await received.future;
    cancellation.cancel();
    await expectation;
  });

  test(
    'refused port leaves HTTP unexecuted instead of manufacturing a result',
    () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      await server.close();
      final cancellation = DiagnosticCancellation();
      addTearDown(cancellation.cancel);
      final target = DiagnosticTarget.parseLines(
        'http://127.0.0.1:$port',
      ).single;
      final result = await DesktopNetworkProbe().probe(target, 1, cancellation);
      expect(result.readings[1].outcome, ProbeOutcome.failure);
      expect(result.readings.last.outcome, ProbeOutcome.skipped);
      expect(result.reached, isFalse);
    },
  );
}
