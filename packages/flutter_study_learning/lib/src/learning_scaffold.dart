import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 学习目标展示区块
class LearningObjectives extends StatelessWidget {
  const LearningObjectives({super.key, required this.objectives});

  final List<String> objectives;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '🎯 学习目标',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: objectives
            .map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(child: Text(o)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// 核心概念标签组
class ConceptChips extends StatelessWidget {
  const ConceptChips({super.key, required this.concepts});

  final List<String> concepts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: concepts
            .map(
              (c) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// 代码片段展示卡片
class CodeSnippetCard extends StatelessWidget {
  const CodeSnippetCard({
    super.key,
    required this.title,
    required this.code,
    this.explanation,
  });

  final String title;
  final String code;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '📝 $title',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已复制到剪贴板'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                tooltip: '复制代码',
              ),
              if (explanation != null)
                Expanded(
                    child: Text(explanation!,
                        style: const TextStyle(fontSize: 12))),
            ],
          ),
        ],
      ),
    );
  }
}

/// 状态变化/日志展示区
class StateLogView extends StatelessWidget {
  const StateLogView({super.key, required this.logs, this.maxLines = 8});

  final List<String> logs;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '📊 状态日志',
      child: Container(
        constraints: BoxConstraints(maxHeight: maxLines * 20),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            return Text(
              logs[index],
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            );
          },
        ),
      ),
    );
  }
}

/// 常见误区提示
class CommonPitfalls extends StatelessWidget {
  const CommonPitfalls({super.key, required this.pitfalls});

  final List<String> pitfalls;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '⚠️ 常见误区',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: pitfalls
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// 练习任务卡片
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({super.key, required this.task, this.hint});

  final String task;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '💪 练习任务',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              '提示: $hint',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}

/// 教学区块容器
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// 标准教学页面脚手架
class LearningScaffold extends StatelessWidget {
  const LearningScaffold({
    super.key,
    required this.title,
    required this.sections,
    this.interactiveDemo,
    this.floatingActionButton,
  });

  final String title;
  final List<Widget> sections;
  final Widget? interactiveDemo;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (interactiveDemo != null) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: interactiveDemo),
                ),
              ),
              const Divider(),
            ],
            ...sections,
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
