import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import 'package:provider/provider.dart';

import '../../widgets/state_flow_demo.dart';
import 'models/counter_cn.dart';
import 'widgets/provider_perks.dart';

class ProviderRoute extends StatelessWidget {
  const ProviderRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        debugPrint('[Provider] 创建 CounterCN，并开始监听 notifyListeners');
        return CounterCN();
      },
      child: Builder(
        builder: (context) {
          final value = context.select<CounterCN, int>((s) => s.value);
          debugPrint('[Provider] 顶层 build，仅监听 value=$value');
          final counter = context.read<CounterCN>();

          return LearningScaffold(
            title: 'Provider / ChangeNotifier',
            interactiveDemo: StateFlowDemo(
              pageTitle: 'Provider / ChangeNotifier',
              subtitle:
                  'notifyListeners() → Provider 找到依赖字段 → markNeedsBuild()',
              value: value,
              flowSteps: const [
                'onPressed 事件',
                'value++ / leafTaps++',
                'notifyListeners()',
                '依赖字段 Widget 重建',
              ],
              onAdd: counter.increment,
              onReset: counter.reset,
              extra: const ProviderPerks(),
            ),
            sections: [
              LearningObjectives(objectives: [
                '理解 Provider + ChangeNotifier 的状态刷新链路',
                '掌握 context.select 的粒度刷新机制',
              ]),
              ConceptChips(concepts: [
                'Provider',
                'ChangeNotifier',
                'notifyListeners',
                'context.select',
              ]),
              CodeSnippetCard(
                title: 'Provider 粒度刷新',
                code: 'final value = context.select<CN, int>((s) => s.value);\n'
                    'context.read<CN>().increment();',
                explanation: 'select 只监听指定字段，字段未变时 Widget 不会重建。',
              ),
              ExerciseCard(
                task: '点击"加 1"按钮，观察控制台日志中 Provider 的刷新链路。',
                hint: 'ProviderPerks 组件展示了额外字段的独立刷新效果。',
              ),
            ],
          );
        },
      ),
    );
  }
}
