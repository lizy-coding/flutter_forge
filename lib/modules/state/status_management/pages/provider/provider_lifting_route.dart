import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import 'package:provider/provider.dart';

class ProviderLiftingRoute extends StatelessWidget {
  const ProviderLiftingRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _LiftingCN(),
      child: _LiftingContent(),
    );
  }
}

class _LiftingCN extends ChangeNotifier {
  int value = 0;
  void inc() {
    value++;
    notifyListeners();
  }

  void reset() {
    value = 0;
    notifyListeners();
  }
}

class _LiftingContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Provider 状态提升',
      interactiveDemo: SizedBox(
        height: 200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LDisplay(),
            const SizedBox(height: 16),
            _LControls(),
          ],
        ),
      ),
      sections: [
        LearningObjectives(objectives: [
          '理解 Provider 状态提升 (Lifting State Up) 模式',
          '掌握父级集中管理状态、子组件共享的模式',
        ]),
        ConceptChips(concepts: [
          '状态提升',
          'Provider',
          'ChangeNotifier',
          '共享状态',
        ]),
        CodeSnippetCard(
          title: '状态提升模式',
          code: 'ChangeNotifierProvider(\n'
              '  create: (_) => _LiftingCN(),\n'
              '  child: _LDisplay(),\n'
              ');\n'
              '// _LDisplay 和 _LControls 共享同一个 Provider',
          explanation:
              '将状态提升到父级 Provider 中，子组件通过 context.select 或 context.read 访问。',
        ),
        ExerciseCard(
          task: '添加一个新的子组件来消费 _LiftingCN 状态，观察共享效果。',
          hint: '在 _LiftingContent 的 Column 中添加一个新 StatelessWidget。',
        ),
      ],
    );
  }
}

class _LDisplay extends StatelessWidget {
  const _LDisplay();
  @override
  Widget build(BuildContext context) {
    final v = context.select<_LiftingCN, int>((s) => s.value);
    return Text('$v', style: Theme.of(context).textTheme.headlineMedium);
  }
}

class _LControls extends StatelessWidget {
  const _LControls();
  @override
  Widget build(BuildContext context) {
    final s = context.read<_LiftingCN>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
            onPressed: s.inc,
            icon: const Icon(Icons.exposure_plus_1),
            label: const Text('加 1')),
        const SizedBox(width: 12),
        OutlinedButton.icon(
            onPressed: s.reset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('重置')),
      ],
    );
  }
}
