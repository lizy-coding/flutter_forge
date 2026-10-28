import 'dart:async';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:go_router/go_router.dart';
import '../module_registry/module_entry.dart';
import '../module_registry/app_platform_snapshot.dart';
import '../shared/genui/model_connection_dialog.dart';
import '../shared/platform/build_features.dart';
import 'module_discovery_replay.dart';
import 'module_discovery_session.dart';
import 'module_discovery_surface.dart';

class ModuleDiscoveryPanel extends StatefulWidget {
  const ModuleDiscoveryPanel({
    super.key,
    required this.modules,
    required this.platform,
    this.session,
    this.recentPaths = const [],
  });
  final List<ModuleEntry> modules;
  final AppPlatformSnapshot platform;
  final ModuleDiscoverySession? session;
  final List<String> recentPaths;
  @override
  State<ModuleDiscoveryPanel> createState() => _ModuleDiscoveryPanelState();
}

class _ModuleDiscoveryPanelState extends State<ModuleDiscoveryPanel> {
  late final session =
      widget.session ??
      ModuleDiscoverySession(
        modules: widget.modules,
        platform: widget.platform,
        recentPaths: widget.recentPaths,
        openModule: (path) => context.go(path),
        // Visitors get the labelled offline replay; the toolbar button swaps
        // in a live model source.
        source: ReplayDiscoverySource(
          modules: widget.modules,
          platform: widget.platform,
        ),
      );
  final question = TextEditingController();
  bool focused = false;
  Future<void> connect() async {
    final source = await showModelConnection(context);
    if (source == null) return;
    if (!mounted) {
      source.dispose();
      return;
    }
    session.setSource(source);
  }

  Future<void> submit() async {
    if (question.text.trim().isEmpty) return;
    await session.submit(question.text);
  }

  @override
  void dispose() {
    question.dispose();
    if (widget.session == null) session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (_, _) {
      final colors = Theme.of(context).colorScheme;
      final reduced =
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context);
      return Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '探索，从好奇开始',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: colors.primary),
                  ),
                  const Spacer(),
                  if (!offlineEdition)
                    IconButton(
                      onPressed: session.busy ? null : connect,
                      tooltip: session.connected ? '更换模型服务' : '连接真实模型',
                      icon: const Icon(Icons.tune_rounded, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '今天，想弄明白什么？',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '从一个问题出发，找到值得动手的实验。',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              Focus(
                onFocusChange: (value) => setState(() => focused = value),
                child: DiscoverySurface(
                  highlighted: focused,
                  radius: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: const ValueKey('discovery-question'),
                          controller: question,
                          minLines: 2,
                          maxLines: 5,
                          maxLength: 1500,
                          enabled: !session.busy,
                          decoration: const InputDecoration(
                            hintText: '比如：异步任务为什么会卡住界面？',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            counterText: '',
                            filled: false,
                          ),
                          onSubmitted: (_) => unawaited(submit()),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              session.connected
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.replay_rounded,
                              size: 14,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                session.connected ? '模型已连接' : '固定回放 · 未调用模型',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ),
                            if (session.busy)
                              IconButton(
                                onPressed: session.cancel,
                                tooltip: '取消生成',
                                icon: const Icon(Icons.stop_rounded),
                              )
                            else
                              FilledButton(
                                onPressed: submit,
                                key: const ValueKey('discovery-submit'),
                                style: FilledButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(14),
                                  minimumSize: const Size(48, 48),
                                ),
                                child: const Icon(
                                  Icons.arrow_upward_rounded,
                                  semanticLabel: '生成探索入口',
                                  size: 22,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final entry in const {
                    '布局与尺寸': '为什么设置宽度后没有生效？',
                    '异步与并发': '异步任务为什么会卡界面？',
                    '网络与设备': '想学习如何判断网络故障',
                  }.entries)
                    TextButton.icon(
                      onPressed: session.busy
                          ? null
                          : () {
                              question.text = entry.value;
                            },
                      icon: const Icon(Icons.north_east_rounded, size: 14),
                      label: Text(entry.key),
                    ),
                ],
              ),
              AnimatedContainer(
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (session.busy)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: reduced
                                  ? const Icon(
                                      Icons.hourglass_empty_rounded,
                                      size: 16,
                                    )
                                  : CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.primary,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('正在为你整理探索方向…')),
                          ],
                        ),
                      ),
                    if (session.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: colors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                session.error!,
                                style: TextStyle(color: colors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (session.hasSurface) ...[
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '为这次好奇，找到入口',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (session.isReplay)
                            Container(
                              key: const ValueKey('discovery-replay-badge'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: colors.outlineVariant,
                                ),
                              ),
                              child: Text(
                                '固定回放',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ),
                        ],
                      ),
                      if (session.localFilterLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: InputChip(
                              key: const ValueKey('discovery-filter-chip'),
                              label: Text('本地过滤：${session.localFilterLabel}'),
                              tooltip: '清除本地过滤，恢复完整推荐',
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: session.busy
                                  ? null
                                  : session.clearLocalFilter,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Surface(
                        surfaceContext: session.controller.contextFor(
                          discoverySurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (session.records.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ExpansionTile(
                    key: const PageStorageKey('discovery-records-expanded'),
                    title: const Text('查看探索记录'),
                    children: [
                      for (final record in session.records)
                        ListTile(dense: true, title: Text(record)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}
