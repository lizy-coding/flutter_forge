import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

import '../../widgets/state_flow_demo.dart';
import 'counter_bloc.dart';
import 'counter_event.dart';
import 'counter_state.dart';

class BlocRoute extends StatelessWidget {
  const BlocRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterBloc()..add(LoadInitial()),
      child: BlocBuilder<CounterBloc, CounterState>(
        builder: (context, state) {
          final bloc = context.read<CounterBloc>();
          return LearningScaffold(
            title: 'Bloc / flutter_bloc',
            interactiveDemo: StateFlowDemo(
              pageTitle: 'Bloc / flutter_bloc',
              subtitle: 'on<Event> → emit(State) → BlocBuilder 重建',
              value: state.value,
              flowSteps: const [
                'onPressed 事件',
                'add(Event)',
                'Bloc 逻辑处理',
                'emit(State)',
                '订阅者重建',
              ],
              onAdd: () => bloc.add(IncrementPressed()),
              onReset: () => bloc.add(ResetPressed()),
            ),
            sections: [
              LearningObjectives(
                objectives: [
                  '理解 Bloc 的事件驱动状态管理机制',
                  '掌握 Event → Bloc → State 的完整链路',
                ],
              ),
              ConceptChips(
                concepts: ['Bloc', 'Event', 'State', 'emit', 'BlocBuilder'],
              ),
              CodeSnippetCard(
                title: 'Bloc 核心模式',
                code:
                    'class CounterBloc extends Bloc<CounterEvent, CounterState> {\n'
                    '  CounterBloc() : super(CounterState(0)) {\n'
                    '    on<IncrementPressed>((e, emit) {\n'
                    '      emit(state.copyWith(value: state.value + 1));\n'
                    '    });\n'
                    '  }\n'
                    '}',
                explanation: 'Event 驱动 Bloc 逻辑处理，通过 emit 发送新 State 触发 UI 重建。',
              ),
              ExerciseCard(
                task: '在 Bloc 中添加"减 1"功能，观察事件驱动的完整链路。',
                hint:
                    '添加 DecrementPressed 事件类，在 CounterBloc 中注册 on<DecrementPressed>。',
              ),
            ],
          );
        },
      ),
    );
  }
}
