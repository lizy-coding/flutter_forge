import 'diagnostic_models.dart';
import 'diagnostic_session.dart';

class TargetSummary {
  TargetSummary(this.target, List<ProbeSample> all)
    : samples = all.where((s) => s.target.uri == target.uri).toList();
  final DiagnosticTarget target;
  final List<ProbeSample> samples;
  int get reached => samples.where((s) => s.reached).length;
  int get failures => samples.length - reached;
  String get failedPercent => samples.isEmpty
      ? '未测量'
      : '${(failures * 100 / samples.length).toStringAsFixed(0)}%';
  String get responseTime {
    final values = samples
        .where((s) => s.reached)
        .map((s) => s.readings.last.elapsed.inMicroseconds / 1000)
        .toList();
    return values.isEmpty
        ? '未取得'
        : '${(values.reduce((a, b) => a + b) / values.length).toStringAsFixed(1)} ms';
  }

  String get conclusion {
    if (samples.isEmpty) return '尚无观测，不能判断';
    if (reached == 0) return '本次观测未完成目标连接／请求';
    if (failures > 0) return '观测到成功与失败交替，建议延长观察并检查网络变化';
    if (samples.any((s) => s.applicationWarning)) {
      return '服务已响应，但有 HTTP 错误状态；请检查服务或访问权限';
    }
    return target.isTcp ? '本次端口连接成功，业务状态未检测' : '本次目标已响应，不代表所有网站或业务正常';
  }
}

String diagnosticConclusion(DiagnosticSession session) {
  if (session.samples.isEmpty) return '尚无完成的目标观测，证据不足。';
  final reached = session.samples.where((s) => s.reached).length;
  if (reached == 0) return '本次目标均未完成连接／请求；可能涉及本机网络、解析、路径或目标服务，不能直接认定整体断网。';
  if (reached < session.samples.length) {
    return '部分观测成功、部分失败。请展开目标详情，区分目标差异与间歇性失败。';
  }
  if (session.samples.any((s) => s.applicationWarning)) {
    return '已收到目标响应，但存在 HTTP 错误状态；网络可达不等于业务可用。';
  }
  return '本次已完成的目标观测均有响应；结论仅适用于列出的目标和观测时段。';
}

String diagnosticReport(
  DiagnosticSession session, {
  required bool hideSensitive,
}) {
  final lines = <String>[
    '网络诊断报告',
    '状态：${session.stateLabel}',
    '现象：${session.symptom.label}',
    '开始：${session.startedAt?.toLocal().toIso8601String() ?? '未知'}',
    '结束：${session.finishedAt?.toLocal().toIso8601String() ?? '进行中'}',
    '完成观测：${session.samples.length}/${session.plannedSamples}',
    '系统：${session.snapshot?.system ?? '未取得'}',
    '网卡：${hideSensitive ? '[已隐藏网卡名称与本机地址]' : (session.snapshot?.interfaces.join('; ') ?? '未取得')}',
    if (session.snapshot?.note != null) session.snapshot!.note!,
    if (session.snapshot != null) ...[
      session.snapshot!.vpn.text,
      session.snapshot!.dnsIntegrity.text,
    ],
    diagnosticConclusion(session),
  ];
  for (var index = 0; index < session.targets.length; index++) {
    final target = session.targets[index];
    final summary = TargetSummary(target, session.samples);
    lines.addAll([
      '',
      '目标 ${index + 1}：${hideSensitive ? '[地址已隐藏]' : target.uri}',
      '协议：${target.uri.scheme}；端口：${target.uri.port}',
      '完成 ${summary.samples.length}/${session.rounds} 轮；响应 ${summary.reached}；请求／连接失败率 ${summary.failedPercent}',
      '末阶段成功观测平均耗时：${summary.responseTime}',
      summary.conclusion,
      for (final sample in summary.samples) ...[
        '第 ${sample.round} 轮',
        for (final check in sample.securityChecks) check.text,
        for (final reading in sample.readings)
          '${reading.label} · ${reading.outcome.name} · ${reading.elapsed.inMilliseconds} ms · ${reading.detail}'
              '${reading.addresses.isEmpty
                  ? ''
                  : hideSensitive
                  ? ' · [解析地址已隐藏]'
                  : ' · ${reading.addresses.join(', ')}'}',
      ],
    ]);
  }
  lines.addAll([
    '',
    '建议：解析失败时检查网络与 DNS 配置；连接失败时核对地址、端口、防火墙与服务状态；HTTP 错误时检查权限及服务配置。这些是排查方向，不是根因证明。',
    '使用应用直接连接，不读取系统代理；VPN 路由仍可能影响结果。DNS、TCP、HTTP 分别执行，HTTP 耗时包含重新连接及 HTTPS 握手。',
    '仅发送 HEAD，不跟随重定向、不下载正文；服务可能不支持 HEAD。失败率不是丢包率，耗时不是带宽测速，有限观测无法排除间歇故障。',
    '未采集 Wi-Fi 名称、网关、系统 DNS 配置及链路往返时延；未修改系统设置，未调用 AI。',
  ]);
  return lines.join('\n');
}
