import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

class RiverpodFutureRoute extends ConsumerWidget {
  const RiverpodFutureRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_userProvider);
    return LearningScaffold(
      title: 'Riverpod 数据获取与缓存',
      interactiveDemo: SizedBox(
        height: 200,
        child: Center(
          child: async.when(
            data: (v) =>
                Text(v, style: Theme.of(context).textTheme.headlineSmall),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
        ),
      ),
      sections: [
        LearningObjectives(objectives: [
          '掌握 Riverpod FutureProvider 的异步数据管理',
          '理解 when() 方法处理 loading/data/error 三态',
        ]),
        ConceptChips(concepts: [
          'Riverpod',
          'FutureProvider',
          'async',
          'when',
          '缓存',
        ]),
        CodeSnippetCard(
          title: 'FutureProvider 模式',
          code: 'final userProvider = FutureProvider<String>((ref) async {\n'
              '  await Future.delayed(Duration(milliseconds: 300));\n'
              '  return "Alice";\n'
              '});\n'
              '// ref.watch(userProvider) 返回 AsyncValue<String>',
          explanation: 'FutureProvider 自动处理 loading/data/error 状态，无需手动管理。',
        ),
        ExerciseCard(
          task: '添加"刷新"按钮来重新加载数据，验证缓存机制。',
          hint: '使用 ref.invalidate(userProvider) 可使缓存失效并触发重新加载。',
        ),
      ],
    );
  }
}

final _userProvider = FutureProvider<String>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return 'Alice';
});
