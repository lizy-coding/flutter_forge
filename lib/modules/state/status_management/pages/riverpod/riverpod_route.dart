import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

import '../../widgets/state_flow_demo.dart';

class RiverpodRoute extends ConsumerWidget {
  const RiverpodRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    debugPrint('[Riverpod] Consumer build，state=$count');

    return LearningScaffold(
      title: 'Riverpod / StateNotifier',
      interactiveDemo: StateFlowDemo(
        pageTitle: 'Riverpod / StateNotifier',
        subtitle: 'state = newState → ProviderContainer 广播 → 订阅者重建',
        value: count,
        flowSteps: const [
          'onPressed 事件',
          'state = newState',
          '容器 diff 并广播',
          '监听者 build()',
        ],
        onAdd: () => ref.read(counterProvider.notifier).increment(),
        onReset: () => ref.read(counterProvider.notifier).reset(),
      ),
      sections: [
        LearningObjectives(objectives: [
          '理解 Riverpod StateNotifier 的状态管理机制',
          '掌握 Provider 容器广播与消费者重建的关系',
        ]),
        ConceptChips(concepts: [
          'Riverpod',
          'StateNotifier',
          'ProviderContainer',
          'ref.watch',
          'ref.read',
        ]),
        CodeSnippetCard(
          title: 'Riverpod 核心模式',
          code:
              'final provider = StateNotifierProvider<RP, int>((ref) => RP());\n'
              'class RP extends StateNotifier<int> {\n'
              '  void increment() => state = state + 1;\n'
              '}',
          explanation: 'state = newState 自动触发依赖广播，无需手动调用通知方法。',
        ),
        ExerciseCard(
          task: '观察 ref.watch 与 ref.read 的区别，理解监听 vs 一次性读取。',
          hint: 'watch 会订阅变化，read 只获取当前值不订阅。',
        ),
      ],
    );
  }
}

final counterProvider = StateNotifierProvider<CounterRP, int>((ref) {
  debugPrint('[Riverpod] 创建 CounterRP');
  return CounterRP();
});

class CounterRP extends StateNotifier<int> {
  CounterRP() : super(0);

  void increment() {
    final old = state;
    state = state + 1;
    debugPrint('[Riverpod] increment: $old -> $state (自动通知依赖)');
  }

  void reset() {
    state = 0;
    debugPrint('[Riverpod] reset -> 0');
  }
}
