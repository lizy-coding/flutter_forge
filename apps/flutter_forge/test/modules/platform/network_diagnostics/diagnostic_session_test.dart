import 'dart:async';

import 'package:flutter_forge_app/modules/platform/network_diagnostics/diagnostic_models.dart';
import 'package:flutter_forge_app/modules/platform/network_diagnostics/diagnostic_report.dart';
import 'package:flutter_forge_app/modules/platform/network_diagnostics/diagnostic_session.dart';
import 'package:flutter_forge_app/modules/platform/network_diagnostics/network_probe.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProbe implements NetworkProbe {
  Future<ProbeSample> Function(DiagnosticTarget, int)? action;
  int calls = 0;

  @override
  Future<NetworkSnapshot> snapshot(DiagnosticCancellation cancellation) async =>
      const NetworkSnapshot(
        system: 'test',
        interfaces: ['private-wifi: 192.168.7.9'],
      );

  @override
  Future<ProbeSample> probe(
    DiagnosticTarget target,
    int round,
    DiagnosticCancellation cancellation,
  ) async {
    calls++;
    if (action != null) return action!(target, round);
    return sample(target, round);
  }
}

ProbeSample sample(
  DiagnosticTarget target,
  int round, {
  bool reached = true,
  int status = 200,
}) => ProbeSample(
  target: target,
  round: round,
  readings: [
    const ProbeReading(
      stage: ProbeStage.dns,
      outcome: ProbeOutcome.success,
      elapsed: Duration(milliseconds: 2),
      detail: '解析完成',
      addresses: ['10.99.8.7'],
    ),
    ProbeReading(
      stage: ProbeStage.http,
      outcome: reached ? ProbeOutcome.success : ProbeOutcome.failure,
      elapsed: const Duration(milliseconds: 20),
      detail: reached ? '收到响应' : '超时',
      statusCode: reached ? status : null,
    ),
  ],
);

void main() {
  final targets = DiagnosticTarget.parseLines(
    'https://private.example/secret-path\nhttps://other.example/',
  );

  test(
    'target input validates credential-free protocols and bounded unique targets',
    () {
      expect(DiagnosticTarget.parseLines('example.com\nexample.com').length, 1);
      expect(
        DiagnosticTarget.parseLines('tcp://[::1]:8080').single.uri.port,
        8080,
      );
      for (final value in [
        '',
        'file:///tmp/a',
        'https://user:pass@example.com',
        'https://example.com?token=abc',
        'https://example.com/#secret',
        'tcp://example.com',
        'tcp://example.com:80/path',
        'https://example.com:99999',
        'http://bad host/',
      ]) {
        expect(
          () => DiagnosticTarget.parseLines(value),
          throwsFormatException,
          reason: value,
        );
      }
      expect(
        () => DiagnosticTarget.parseLines(
          List.generate(5, (i) => 'https://host$i.example').join('\n'),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'HTTP error status remains evidence of response, with a service warning',
    () async {
      final probe = FakeProbe()
        ..action = (target, round) async => sample(target, round, status: 403);
      final session = DiagnosticSession(probe: probe);
      addTearDown(session.dispose);
      await session.start(targets, DiagnosticSymptom.target);
      expect(session.state, DiagnosticState.completed);
      expect(TargetSummary(targets.first, session.samples).failures, 0);
      expect(diagnosticConclusion(session), contains('HTTP 错误状态'));
    },
  );

  test(
    'five rounds preserve target-specific failures and calculate completed request rate',
    () async {
      final probe = FakeProbe()
        ..action = (target, round) async => sample(
          target,
          round,
          reached: target == targets.first && round.isOdd,
        );
      final session = DiagnosticSession(probe: probe, interval: Duration.zero);
      addTearDown(session.dispose);
      await session.start(targets, DiagnosticSymptom.intermittent);
      expect(probe.calls, 10);
      expect(session.samples.length, 10);
      expect(session.progress, 1);
      final first = TargetSummary(targets.first, session.samples);
      expect(first.failedPercent, '40%');
      expect(first.responseTime, '20.0 ms');
      expect(first.conclusion, contains('成功与失败交替'));
      expect(TargetSummary(targets.last, session.samples).reached, 0);
    },
  );

  test(
    'all target failures do not assert total internet outage or a proven cause',
    () async {
      final probe = FakeProbe()
        ..action = (target, round) async =>
            sample(target, round, reached: false);
      final session = DiagnosticSession(probe: probe);
      addTearDown(session.dispose);
      await session.start(targets, DiagnosticSymptom.offline);
      expect(diagnosticConclusion(session), contains('不能直接认定整体断网'));
    },
  );

  test(
    'report hides all host, path, interface and resolved-address fields by default choice',
    () async {
      final session = DiagnosticSession(probe: FakeProbe());
      addTearDown(session.dispose);
      await session.start(targets, DiagnosticSymptom.offline);
      final hidden = diagnosticReport(session, hideSensitive: true);
      final raw = diagnosticReport(session, hideSensitive: false);
      for (final secret in [
        'private.example',
        'secret-path',
        'other.example',
        'private-wifi',
        '192.168.7.9',
        '10.99.8.7',
      ]) {
        expect(hidden, isNot(contains(secret)), reason: secret);
        expect(raw, contains(secret));
      }
      expect(hidden, contains('完成观测：2/2'));
    },
  );

  test(
    'cancel returns without waiting for backend and rejects late results before a new run',
    () async {
      final pending = Completer<ProbeSample>();
      final entered = Completer<void>();
      final probe = FakeProbe()
        ..action = (target, round) {
          if (!entered.isCompleted) entered.complete();
          return pending.future;
        };
      final session = DiagnosticSession(probe: probe);
      addTearDown(session.dispose);
      final run = session.start([targets.first], DiagnosticSymptom.offline);
      await entered.future;
      session.cancel();
      await run;
      expect(session.state, DiagnosticState.cancelled);
      expect(session.samples, isEmpty);
      probe.action = null;
      await session.start([targets.last], DiagnosticSymptom.target);
      pending.complete(sample(targets.first, 1));
      await Future<void>.delayed(Duration.zero);
      expect(session.state, DiagnosticState.completed);
      expect(session.samples.single.target, targets.last);
    },
  );

  test(
    'session deadline preserves incomplete status instead of a network-failure sample',
    () async {
      final pending = Completer<ProbeSample>();
      final probe = FakeProbe()..action = (_, _) => pending.future;
      final session = DiagnosticSession(
        probe: probe,
        sessionBudget: const Duration(milliseconds: 30),
      );
      addTearDown(session.dispose);
      await session.start([targets.first], DiagnosticSymptom.offline);
      expect(session.state, DiagnosticState.timedOut);
      expect(session.samples, isEmpty);
      expect(
        TargetSummary(targets.first, session.samples).failedPercent,
        '未测量',
      );
      pending.complete(sample(targets.first, 1));
    },
  );

  test(
    'dispose cancels active work without notifying after disposal',
    () async {
      final pending = Completer<ProbeSample>();
      final entered = Completer<void>();
      final probe = FakeProbe()
        ..action = (_, _) {
          entered.complete();
          return pending.future;
        };
      final session = DiagnosticSession(probe: probe);
      final run = session.start([targets.first], DiagnosticSymptom.offline);
      await entered.future;
      session.dispose();
      await run;
      pending.complete(sample(targets.first, 1));
      await Future<void>.delayed(Duration.zero);
      expect(session.samples, isEmpty);
    },
  );
}
