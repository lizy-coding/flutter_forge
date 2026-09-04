import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import 'package:provider/provider.dart';

class ProviderFutureRoute extends StatelessWidget {
  const ProviderFutureRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _UserModel()..load(),
      child: _FutureContent(),
    );
  }
}

class _UserModel extends ChangeNotifier {
  String? name;
  Future<void> load() async {
    await Future.delayed(const Duration(milliseconds: 300));
    name = 'Alice';
    notifyListeners();
  }
}

class _FutureContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Provider 数据获取与缓存',
      interactiveDemo: SizedBox(
        height: 200,
        child: Center(
          child: Consumer<_UserModel>(
            builder: (_, m, __) => m.name == null
                ? const CircularProgressIndicator()
                : Text(
                    m.name!,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
          ),
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: ['掌握 Provider 中异步数据获取的模式', '理解 ChangeNotifier 中的状态缓存机制'],
        ),
        ConceptChips(concepts: ['Provider', 'Future', '缓存', 'ChangeNotifier']),
        CodeSnippetCard(
          title: 'Provider 异步加载',
          code:
              'class _UserModel extends ChangeNotifier {\n'
              '  String? name;\n'
              '  Future<void> load() async {\n'
              '    name = await fetchUser();\n'
              '    notifyListeners();\n'
              '  }\n'
              '}',
          explanation: 'load 方法执行异步操作后调用 notifyListeners 触发 UI 更新。',
        ),
        ExerciseCard(
          task: '添加错误处理状态，当加载失败时显示错误提示。',
          hint: '在 _UserModel 中添加 error 字段和 setState 条件分支。',
        ),
      ],
    );
  }
}
