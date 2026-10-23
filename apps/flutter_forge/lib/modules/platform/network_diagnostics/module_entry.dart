import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import 'diagnostic_models.dart';
import 'diagnostic_report.dart';
import 'diagnostic_session.dart';
import 'network_probe.dart';

class NetworkDiagnosticsEntry extends StatefulWidget {
  const NetworkDiagnosticsEntry({super.key, this.probe});
  final NetworkProbe? probe;

  @override
  State<NetworkDiagnosticsEntry> createState() =>
      _NetworkDiagnosticsEntryState();
}

class _NetworkDiagnosticsEntryState extends State<NetworkDiagnosticsEntry> {
  late final DiagnosticSession session;
  final targetsController = TextEditingController(
    text: DiagnosticTarget.defaults,
  );
  DiagnosticSymptom symptom = DiagnosticSymptom.offline;
  String? inputError;

  @override
  void initState() {
    super.initState();
    session = DiagnosticSession(probe: widget.probe);
  }

  @override
  void dispose() {
    session.dispose();
    targetsController.dispose();
    super.dispose();
  }

  void start() {
    try {
      final targets = DiagnosticTarget.parseLines(targetsController.text);
      setState(() => inputError = null);
      unawaited(session.start(targets, symptom));
    } on FormatException catch (error) {
      setState(() => inputError = error.message);
    }
  }

  Future<void> previewReport() async {
    var hidden = true;
    String? copyError;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) {
          final report = diagnosticReport(session, hideSensitive: hidden);
          return AlertDialog(
            title: const Text('报告预览'),
            content: SizedBox(
              width: 640,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('隐藏目标、网卡名称及 IP 地址'),
                    value: hidden,
                    onChanged: (value) => update(() => hidden = value ?? true),
                  ),
                  if (copyError != null) Text(copyError!),
                  Flexible(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        report,
                        key: const Key('diagnostic-report-preview'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('关闭'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: report));
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('已复制预览中的报告')),
                      );
                    }
                  } catch (_) {
                    if (dialogContext.mounted) {
                      update(() => copyError = '复制失败，请选择报告文本手动复制。');
                    }
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('复制报告'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => LearningScaffold(
      title: '网络诊断：从现象到检测证据',
      interactiveDemo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('先看现象，再看证据', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('检测只在你点击后开始。直接访问列出的目标，不修改系统设置。'),
          const SizedBox(height: 16),
          DropdownButtonFormField<DiagnosticSymptom>(
            initialValue: symptom,
            decoration: const InputDecoration(
              labelText: '遇到的问题',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final item in DiagnosticSymptom.values)
                DropdownMenuItem(value: item, child: Text(item.label)),
            ],
            onChanged: session.running
                ? null
                : (value) => setState(() => symptom = value!),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('diagnostic-targets'),
            controller: targetsController,
            enabled: !session.running,
            minLines: 2,
            maxLines: 5,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: '检测目标（每行一个，最多四个）',
              hintText: 'https://example.com/\ntcp://192.168.1.1:80',
              helperText: '支持 HTTP(S) 或 TCP 端口；默认地址可替换，不保证服务一直可用。',
              helperMaxLines: 3,
              errorText: inputError,
              errorMaxLines: 4,
              border: const OutlineInputBorder(),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: session.running
                  ? null
                  : () => setState(() {
                      targetsController.text = DiagnosticTarget.defaults;
                      inputError = null;
                    }),
              icon: const Icon(Icons.restore),
              label: const Text('恢复默认目标'),
            ),
          ),
          Text(
            symptom == DiagnosticSymptom.intermittent
                ? '观察模式：每个目标五轮，轮间隔一秒，整次检测最多 60 秒。'
                : '快速模式：每个目标一轮，整次检测最多 60 秒。',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('diagnostic-start'),
                onPressed: session.running ? null : start,
                icon: const Icon(Icons.network_check),
                label: Text(
                  session.state == DiagnosticState.idle ? '一键检测' : '重新检测',
                ),
              ),
              if (session.running)
                OutlinedButton.icon(
                  onPressed: session.cancel,
                  icon: const Icon(Icons.stop),
                  label: const Text('取消检测'),
                ),
              OutlinedButton.icon(
                onPressed: session.running || session.startedAt == null
                    ? null
                    : previewReport,
                icon: const Icon(Icons.description_outlined),
                label: const Text('预览／复制报告'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Semantics(
            liveRegion: true,
            child: Text(
              session.stateLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (session.running) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: session.progress),
          ],
          if (session.startedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '完成观测 ${session.samples.length}/${session.plannedSamples}；报告仅保留在当前页面会话。',
            ),
            const SizedBox(height: 8),
            Text(diagnosticConclusion(session)),
            if (session.error != null) Text(session.error!),
            const SizedBox(height: 12),
            const Text(
              '建议：先检查当前连接与其他网站；再根据失败阶段核对 DNS、端口、访问权限或目标服务。未完成观测不计作失败。',
            ),
          ],
          if (session.snapshot != null)
            ExpansionTile(
              title: const Text('基本网络信息'),
              subtitle: Text(
                '系统：${session.snapshot!.system} · ${session.snapshot!.interfaces.length} 个网卡',
              ),
              childrenPadding: const EdgeInsets.all(12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in session.snapshot!.interfaces)
                  SelectableText(item),
                if (session.snapshot!.interfaces.isEmpty)
                  const Text('没有取得可展示的网卡地址，不等同于断网。'),
                if (session.snapshot!.note != null)
                  Text(session.snapshot!.note!),
              ],
            ),
          if (session.snapshot != null) ...[
            const SizedBox(height: 12),
            Text('VPN 与劫持检测', style: Theme.of(context).textTheme.titleMedium),
            Text(session.snapshot!.vpn.text),
            const SizedBox(height: 8),
            Text(session.snapshot!.dnsIntegrity.text),
            const Text('检测为线索检查，无法证明未使用 VPN 或网络完全未被劫持。'),
          ],
          for (final target in session.targets)
            _TargetCard(
              summary: TargetSummary(target, session.samples),
              rounds: session.rounds,
            ),
          const SizedBox(height: 12),
          const Text(
            '检测范围：应用直接连接，不读取系统代理；VPN 路由仍可能影响结果。只发送 HEAD，不跟随重定向、不下载正文。服务可能拒绝 HEAD。',
          ),
          const SizedBox(height: 8),
          const Text(
            '耗时不是带宽测速；请求失败率不是丢包率。未采集 Wi-Fi 名称、网关和系统 DNS 配置，有限观测不能排除所有间歇故障。',
          ),
        ],
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '区分 DNS、TCP 与 HTTP 的检测证据',
            '根据目标差异排查问题，而非把一次失败等同整体断网',
            '理解有界观测、取消和报告隐私',
          ],
        ),
        ConceptChips(
          concepts: [
            'DNS',
            'TCP',
            'TLS',
            'VPN',
            '劫持线索',
            'HTTP HEAD',
            '超时与取消',
            '证据边界',
          ],
        ),
        CommonPitfalls(
          pitfalls: [
            '有本机 IP 不等于可以上网；服务返回 403 或 500 也证明收到了响应',
            'DNS、TCP、HTTP 独立执行；HTTP 耗时包含重新连接与 HTTPS 握手',
            '返回重定向只说明入口响应，不证明跳转后的业务可用',
          ],
        ),
        ExerciseCard(
          task: '分别检测正常网站和未开放的 TCP 端口，比较失败阶段与证据。',
          hint: '使用自己可控的目标，观察“未执行”和“失败”的区别。',
        ),
      ],
    ),
  );
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.summary, required this.rounds});
  final TargetSummary summary;
  final int rounds;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            summary.target.uri.toString(),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(summary.conclusion),
          Text(
            '完成 ${summary.samples.length}/$rounds 轮 · 响应 ${summary.reached} · 失败率 ${summary.failedPercent}',
          ),
          Text(
            '${summary.target.isTcp ? 'TCP 连接' : 'HTTP 响应'}成功观测平均耗时：${summary.responseTime}',
          ),
          for (final sample in summary.samples)
            for (final check in sample.securityChecks)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('第 ${sample.round} 轮 · ${check.text}'),
              ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('展开检测证据'),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (summary.samples.isEmpty) const Text('尚无完成观测。'),
              for (final sample in summary.samples) ...[
                Text(
                  '第 ${sample.round} 轮',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final reading in sample.readings)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reading.label} · ${switch (reading.outcome) {
                            ProbeOutcome.success => '成功',
                            ProbeOutcome.failure => '失败',
                            ProbeOutcome.skipped => '未执行',
                          }} · ${reading.elapsed.inMilliseconds} ms',
                        ),
                        Text(reading.detail),
                        if (reading.addresses.isNotEmpty)
                          SelectableText(
                            '解析地址：${reading.addresses.join(', ')}',
                          ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}
