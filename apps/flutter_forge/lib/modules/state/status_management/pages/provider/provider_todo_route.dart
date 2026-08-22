import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import 'package:provider/provider.dart';

class ProviderTodoRoute extends StatelessWidget {
  const ProviderTodoRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _TodoStore(),
      child: _TodoContent(),
    );
  }
}

class _Todo {
  _Todo(this.title);
  final String title;
  bool done = false;
}

class _TodoStore extends ChangeNotifier {
  final List<_Todo> list = [];
  void add(String t) {
    list.add(_Todo(t));
    notifyListeners();
  }

  void toggle(int i) {
    list[i].done = !list[i].done;
    notifyListeners();
  }

  void remove(int i) {
    list.removeAt(i);
    notifyListeners();
  }
}

class _TodoContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Provider 全局状态示例',
      floatingActionButton: const _AddFab(),
      interactiveDemo: SizedBox(
        height: 400,
        child: Consumer<_TodoStore>(
          builder: (_, store, __) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: store.list.length,
            itemBuilder: (_, i) {
              final item = store.list[i];
              return ListTile(
                title: Text(item.title),
                leading: Checkbox(
                  value: item.done,
                  onChanged: (_) => store.toggle(i),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => store.remove(i),
                ),
              );
            },
          ),
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '掌握 Provider 管理全局列表状态',
            '理解 notifyListeners 在 CRUD 操作中的触发时机',
          ],
        ),
        ConceptChips(concepts: ['Provider', '全局状态', 'CRUD', 'ChangeNotifier']),
        CodeSnippetCard(
          title: 'Provider Todo 模式',
          code:
              'class TodoStore extends ChangeNotifier {\n'
              '  final list = <Todo>[];\n'
              '  void add(String t) { list.add(Todo(t)); notifyListeners(); }\n'
              '  void remove(int i) { list.removeAt(i); notifyListeners(); }\n'
              '}',
          explanation: '每次 CRUD 操作后调用 notifyListeners 通知所有消费者。',
        ),
        ExerciseCard(
          task: '添加"编辑 Todo"功能，修改已有 Todo 的标题。',
          hint: '在 _TodoStore 中添加 edit 方法，使用 TextEditingController 获取新标题。',
        ),
      ],
    );
  }
}

class _AddFab extends StatelessWidget {
  const _AddFab();
  @override
  Widget build(BuildContext context) {
    final store = context.read<_TodoStore>();
    return FloatingActionButton(
      onPressed: () => store.add('Item ${store.list.length + 1}'),
      child: const Icon(Icons.add),
    );
  }
}
