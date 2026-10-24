import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import 'genui_session.dart';
import 'workbench_protocol.dart';
import 'workbench_source.dart';
import '../../../shared/genui/model_connection_dialog.dart';

class GenuiWorkbenchPage extends StatefulWidget {
  const GenuiWorkbenchPage({super.key, this.session});
  final GenuiSession? session;

  @override
  State<GenuiWorkbenchPage> createState() => _GenuiWorkbenchPageState();
}

class _GenuiWorkbenchPageState extends State<GenuiWorkbenchPage> {
  late final _session = widget.session ?? GenuiSession();
  final _question = TextEditingController();

  @override
  void dispose() {
    _question.dispose();
    if (widget.session == null) _session.dispose();
    super.dispose();
  }

  void _submit(String question) {
    _question.text = question;
    unawaited(_session.submit(question));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _session,
    builder: (context, _) => Material(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '生成式实验工作区',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('提出问题，组织实验，观察真实结果，再继续探索。当前仅支持约束小实验，交互能力将逐步完善。'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(label: Text(_session.sourceLabel)),
                    OutlinedButton(
                      onPressed: _configure,
                      child: const Text('连接模型服务'),
                    ),
                    if (!_session.isReplay)
                      TextButton(
                        onPressed: () =>
                            _session.setSource(ReplayWorkbenchSource()),
                        child: const Text('切换固定回放'),
                      ),
                    TextButton(
                      onPressed: _session.reset,
                      child: const Text('重开工作区'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final input = _input();
                    final experiment = _experiment();
                    return constraints.maxWidth >= 860
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 280, child: input),
                              const SizedBox(width: 20),
                              Expanded(child: experiment),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              input,
                              const SizedBox(height: 16),
                              experiment,
                            ],
                          );
                  },
                ),
                const SizedBox(height: 16),
                if (_session.explanationStale)
                  const Text('参数已改变，上一条解释对应旧状态。请重新解释当前结果。'),
                ExpansionTile(
                  title: const Text('观察生成过程'),
                  childrenPadding: const EdgeInsets.all(12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '状态 · ${const JsonEncoder.withIndent('  ').convert(_session.snapshot)}',
                    ),
                    const Divider(),
                    SelectableText(_session.records.join('\n\n')),
                  ],
                ),
                const ExpansionTile(
                  title: Text('理解 GenUI 的完整链路'),
                  children: [
                    LearningObjectives(
                      objectives: [
                        'Catalog 约束模型能使用的组件；A2UI 描述布局与更新。',
                        'SurfaceController 管理组件和 DataModel，Surface 渲染 Flutter Widget。',
                        '参数在本地更新；显式动作经 SDK 回传，再请求下一轮生成。',
                        '尺寸来自 Flutter 布局观测，固定回放不能证明模型理解能力。',
                      ],
                    ),
                    CodeSnippetCard(
                      title: '当前 SDK 0.10.4 的渲染入口',
                      code:
                          "final controller = SurfaceController(catalogs: [catalog]);\n"
                          "Surface(surfaceContext: controller.contextFor('constraint-lab'));",
                    ),
                    ExerciseCard(
                      task: '先改变子组件期望宽度，再切换紧约束；检查实际尺寸，并在事件记录中找到发送给模型的状态。',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _input() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: _question,
        key: const ValueKey('genui-question'),
        minLines: 2,
        maxLines: 4,
        maxLength: 2000,
        decoration: const InputDecoration(
          labelText: '你现在想探索什么问题？',
          hintText: '为什么设置宽度却没有生效？',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: _session.busy ? null : () => _submit(_question.text),
        icon: const Icon(Icons.auto_awesome_outlined),
        label: const Text('组织实验'),
      ),
      const SizedBox(height: 12),
      for (final question in ['为什么设置宽度却没有生效？', '换成紧约束看看', '换成松约束看看'])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: _session.busy ? null : () => _submit(question),
            child: Text(question),
          ),
        ),
      if (_session.busy) ...[
        const LinearProgressIndicator(),
        TextButton(onPressed: _session.cancel, child: const Text('取消生成')),
      ],
      if (_session.error != null) ...[
        Text(
          _session.error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        TextButton(
          onPressed: _session.busy ? null : () => _submit(_session.lastPrompt),
          child: const Text('重试'),
        ),
      ],
    ],
  );

  Widget _experiment() => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: _session.hasExperiment
          ? Surface(
              key: ValueKey(
                'genui-surface-${_session.controller.activeSurfaceIds.join()}',
              ),
              surfaceContext: _session.controller.contextFor(
                workbenchSurfaceId,
              ),
            )
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Text('从左侧或上方选择一个问题，生成你的第一个约束实验。'),
            ),
    ),
  );

  Future<void> _configure() async {
    final source = await showModelConnection(context);
    if (source == null) return;
    if (!mounted) {
      source.dispose();
      return;
    }
    _session.setSource(source);
  }
}
