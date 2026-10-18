import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'scene_render_controller.dart';
import 'scene_render_metrics.dart';

/// Displays bounded scene diagnostics without driving scene repaint requests.
class SceneDiagnosticsPanel extends StatefulWidget {
  const SceneDiagnosticsPanel({
    super.key,
    required this.controller,
    this.readOnly = false,
  });

  final SceneRenderController controller;
  final bool readOnly;

  @override
  State<SceneDiagnosticsPanel> createState() => _SceneDiagnosticsPanelState();
}

class _SceneDiagnosticsPanelState extends State<SceneDiagnosticsPanel> {
  String? _copyStatus;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final metrics = controller.metrics;
        final spec = metrics.specification;
        final enabled = controller.ready && !controller.isDisposed;
        return Card(
          child: ExpansionTile(
            key: const Key('scene-diagnostics'),
            title: const Text('绘制诊断'),
            subtitle: Text(
              '${_modeLabel(controller.mode)} · ${controller.callRate} 次/秒 · ${metrics.sampling ? '采样中' : '采样已停止'}',
            ),
            childrenPadding: const EdgeInsets.all(12),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.readOnly) const Text('当前平台仅显示诊断信息'),
              if (!widget.readOnly)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final mode in SceneRenderMode.values)
                      ChoiceChip(
                        key: Key('render-mode-${mode.name}'),
                        label: Text(_modeLabel(mode)),
                        selected: controller.mode == mode,
                        onSelected: enabled
                            ? (_) => controller.setMode(mode)
                            : null,
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(
                '相机：${controller.camera.motionState.name} · ${controller.visible ? '前台显示' : '已挂起（后台或页面隐藏）'}',
              ),
              Text(
                '绘制驱动：${controller.isFaulted
                    ? '异常暂停，可切换手动重绘后重试'
                    : controller.ticking.value
                    ? '连续驱动中'
                    : '等待变化或单帧请求'}',
              ),
              Text(
                '最近原因：${metrics.lastReason}',
                key: const Key('render-reason'),
              ),
              if (controller.mode == SceneRenderMode.manual)
                const Text('已暂停相机运动与直接操控；单帧重绘保持当前姿态。'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    '渲染调用 ${metrics.renderCalls}',
                    key: const Key('scene-render-count'),
                  ),
                  Text('正常返回 ${metrics.returned} · 异常 ${metrics.failures}'),
                  Text('绘制请求 ${metrics.requests} · 已合并 ${metrics.coalesced}'),
                  Text('调用频率 ${controller.callRate} Hz'),
                ],
              ),
              const SizedBox(height: 8),
              Text('场景调用 CPU：${_summary(metrics.sceneCpu)}'),
              Text('Flutter 窗口 build：${_summary(metrics.windowBuild)}'),
              Text('Flutter 窗口 raster：${_summary(metrics.windowRaster)}'),
              Text(
                '窗口超预算帧：${metrics.overBudgetRatio == null ? '—' : '${(metrics.overBudgetRatio! * 100).toStringAsFixed(1)}%'}',
              ),
              Text(
                '逻辑尺寸 ${spec['logical_width'] ?? '—'} × ${spec['logical_height'] ?? '—'} · 物理像素 ${spec['pixel_width'] ?? '—'} × ${spec['pixel_height'] ?? '—'}',
              ),
              Text(
                'DPR ${spec['device_pixel_ratio'] ?? '—'} · renderScale ${spec['render_scale'] ?? '—'} · 抗锯齿 ${spec['anti_aliasing'] ?? '—'}',
              ),
              Text('刷新率 ${spec['refresh_rate_hz'] ?? '—'} Hz · GPU 后端未采集'),
              const Text('GPU 耗时／显存／draw call：未采集。调用返回不代表 GPU 完成或屏幕首帧。'),
              const SizedBox(height: 8),
              const Text('场景 CPU 趋势 · 最近活动窗口／最多 10 秒与 1200 帧，抓取帧另计'),
              SizedBox(
                height: 64,
                child: CustomPaint(
                  painter: _CpuTrendPainter(
                    metrics.renderSamples
                        .where((s) => !s.capture)
                        .map((s) => s.cpuMicros)
                        .toList(),
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              if (!widget.readOnly)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      key: const Key('render-once'),
                      onPressed:
                          enabled && controller.mode == SceneRenderMode.manual
                          ? controller.redrawOnce
                          : null,
                      child: const Text('重绘一帧'),
                    ),
                    OutlinedButton(
                      key: const Key('render-sampling'),
                      onPressed: enabled
                          ? (metrics.sampling
                                ? controller.stopSampling
                                : controller.startSampling)
                          : null,
                      child: Text(metrics.sampling ? '停止采样' : '开始采样'),
                    ),
                    OutlinedButton(
                      key: const Key('render-clear'),
                      onPressed: controller.clearStatistics,
                      child: const Text('清空统计'),
                    ),
                    OutlinedButton(
                      key: const Key('render-capture'),
                      onPressed: enabled && !controller.capturing
                          ? () => unawaited(controller.captureFrame())
                          : null,
                      child: Text(controller.capturing ? '正在抓取…' : '抓取一帧 Pass'),
                    ),
                    OutlinedButton(
                      key: const Key('render-copy'),
                      onPressed: _copy,
                      child: const Text('复制诊断快照'),
                    ),
                  ],
                ),
              if (_copyStatus != null) Text(_copyStatus!),
              if (controller.capture case final capture?) ...[
                const SizedBox(height: 8),
                Text(
                  '最近抓取：${capture.width} × ${capture.height} px · ${capture.passes.length} Pass',
                  key: const Key('render-capture-result'),
                ),
                for (final pass in capture.passes)
                  Text('${pass.name} · CPU ${_milliseconds(pass.cpuMicros)}'),
              ],
              if (metrics.lastError != null)
                Text(
                  '最近异常：${metrics.lastErrorAt}\n${metrics.lastError}',
                  key: const Key('render-error'),
                ),
              if (metrics.events.isNotEmpty)
                ExpansionTile(
                  title: const Text('最近动作'),
                  children: [
                    for (final event in metrics.events.reversed)
                      ListTile(dense: true, title: Text(event)),
                  ],
                ),
              const SizedBox(height: 8),
              const Text(
                '场景计数来自实际渲染调用；Flutter 帧耗时覆盖当前窗口，不能单独归因于 3D。停止采样后保留最后窗口。',
              ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _copy() async {
    try {
      await Clipboard.setData(
        ClipboardData(text: widget.controller.diagnosticJson()),
      );
      if (mounted) setState(() => _copyStatus = '诊断快照已复制');
    } catch (error) {
      if (mounted) setState(() => _copyStatus = '复制失败：$error');
    }
  }

  static String _modeLabel(SceneRenderMode mode) => switch (mode) {
    SceneRenderMode.onDemand => '按需绘制',
    SceneRenderMode.continuous => '持续绘制',
    SceneRenderMode.manual => '手动重绘',
  };

  static String _milliseconds(int? micros) =>
      micros == null ? '—' : '${(micros / 1000).toStringAsFixed(2)} ms';
  static String _summary(SceneDurationSummary value) =>
      '${value.count} 样本 · 最近 ${_milliseconds(value.latest)} · P50 ${_milliseconds(value.p50)} · P95 ${_milliseconds(value.p95)} · 最大 ${_milliseconds(value.max)}';
}

class _CpuTrendPainter extends CustomPainter {
  const _CpuTrendPainter(this.values, this.color);
  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final ceiling = math.max(1, values.reduce(math.max));
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : i * size.width / (values.length - 1);
      final y = size.height - 2 - values[i] / ceiling * (size.height - 4);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    if (values.length == 1) {
      canvas.drawCircle(
        Offset(
          size.width / 2,
          size.height - 2 - values.first / ceiling * (size.height - 4),
        ),
        2,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CpuTrendPainter oldDelegate) =>
      color != oldDelegate.color || !listEquals(values, oldDelegate.values);
}
