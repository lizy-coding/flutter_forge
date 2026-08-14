import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

class RiverpodTodoRoute extends ConsumerWidget {
  const RiverpodTodoRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TodoContent();
  }
}

class _Todo {
  _Todo(this.title);
  final String title;
  bool done = false;
}

class _TodoRP extends StateNotifier<List<_Todo>> {
  _TodoRP() : super([]);
  void add(String t) => state = [...state, _Todo(t)];
  void toggle(int i) {
    final l = [...state];
    l[i].done = !l[i].done;
    state = l;
  }

  void remove(int i) {
    final l = [...state]..removeAt(i);
    state = l;
  }
}

final _todoProvider = StateNotifierProvider<_TodoRP, List<_Todo>>(
  (ref) => _TodoRP(),
);

class _TodoContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(_todoProvider);
    final n = ref.read(_todoProvider.notifier);
    return LearningScaffold(
      title: 'Riverpod 全局状态示例',
      floatingActionButton: Consumer(
        builder: (context, ref, _) {
          final n2 = ref.read(_todoProvider.notifier);
          return FloatingActionButton(
            onPressed: () =>
                n2.add('Item ${ref.read(_todoProvider).length + 1}'),
            child: const Icon(Icons.add),
          );
        },
      ),
      interactiveDemo: SizedBox(
        height: 400,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final item = list[i];
            return ListTile(
              title: Text(item.title),
              leading: Checkbox(
                value: item.done,
                onChanged: (_) => n.toggle(i),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => n.remove(i),
              ),
            );
          },
        ),
      ),
      sections: [
        LearningObjectives(
          objectives: ['掌握 Riverpod 管理全局列表状态', '理解 StateNotifier 不可变状态更新模式'],
        ),
        ConceptChips(
          concepts: ['Riverpod', '全局状态', 'CRUD', '不可变数据', 'StateNotifier'],
        ),
        CodeSnippetCard(
          title: 'Riverpod Todo 模式',
          code:
              'class TodoRP extends StateNotifier<List<Todo>> {\n'
              '  void add(t) => state = [...state, Todo(t)];\n'
              '  void remove(i) => state = [...state]..removeAt(i);\n'
              '}',
          explanation: 'Riverpod 使用不可变状态更新，每次操作都创建新列表触发广播。',
        ),
        ExerciseCard(
          task: '使用 ref.invalidate 实现"清空所有 Todo"功能。',
          hint: '调用 ref.invalidate(_todoProvider) 可重置状态到初始值。',
        ),
      ],
    );
  }
}
