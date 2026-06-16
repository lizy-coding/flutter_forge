import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

class RiverpodLiftingRoute extends ConsumerWidget {
  const RiverpodLiftingRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LearningScaffold(
      title: 'Riverpod 状态提升',
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
          '理解 Riverpod 的状态提升模式',
          '掌握 Provider 图谱中状态的共享机制',
        ]),
        ConceptChips(concepts: [
          'Riverpod',
          '状态提升',
          'Provider 图谱',
          'StateNotifierProvider',
        ]),
        CodeSnippetCard(
          title: 'Riverpod 状态提升',
          code: 'final liftProvider = StateNotifierProvider<LiftRP, int>(\n'
              '  (ref) => LiftRP(),\n'
              ');\n'
              '// 任意组件可 watch/read 同一 Provider',
          explanation: 'Provider 是全局的，无需 Widget 树传递，任意层级组件均可消费。',
        ),
        ExerciseCard(
          task: '添加第三个组件同时消费 _liftProvider，验证共享状态。',
          hint: '创建一个新的 ConsumerWidget 调用 ref.watch(_liftProvider)。',
        ),
      ],
    );
  }
}

final _liftProvider = StateNotifierProvider<_LiftRP, int>((ref) => _LiftRP());

class _LiftRP extends StateNotifier<int> {
  _LiftRP() : super(0);
  void inc() => state = state + 1;
  void reset() => state = 0;
}

class _LDisplay extends ConsumerWidget {
  const _LDisplay();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(_liftProvider.select((v) => v));
    return Text('$v', style: Theme.of(context).textTheme.headlineMedium);
  }
}

class _LControls extends ConsumerWidget {
  const _LControls();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(_liftProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
            onPressed: n.inc,
            icon: const Icon(Icons.exposure_plus_1),
            label: const Text('加 1')),
        const SizedBox(width: 12),
        OutlinedButton.icon(
            onPressed: n.reset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('重置')),
      ],
    );
  }
}
