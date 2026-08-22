import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import 'package:provider/provider.dart';

import 'model/counter_model.dart';

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final counterModel = Provider.of<CounterModel>(context);

    return LearningScaffold(
      title: 'Flutter IoC 容器',
      floatingActionButton: FloatingActionButton(
        onPressed: counterModel.increment,
        child: const Icon(Icons.add),
      ),
      interactiveDemo: SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Name: ${counterModel.name}',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 12),
              Text(
                'Count: ${counterModel.count}',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) {
                  counterModel.setName(value);
                },
                decoration: const InputDecoration(
                  labelText: 'Enter new name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解 IoC 容器与依赖注入的基本概念',
            '掌握单例、瞬态、作用域三种生命周期',
            '学会使用 Provider 与 IoC 容器集成',
          ],
        ),
        ConceptChips(
          concepts: [
            'IoC',
            '依赖注入',
            'Singleton',
            'Transient',
            'Scoped',
            'Provider',
          ],
        ),
        CodeSnippetCard(
          title: 'IoC 容器注册与使用',
          code:
              'final container = Container(\n'
              "  environment: {'appName': 'Counter'},\n"
              ');\n'
              'container.registerSingleton<CounterModel>(\n'
              '  (_) => CounterModel(name: \'Default\', count: 0),\n'
              ');\n'
              'final model = container.resolve<CounterModel>();',
          explanation: '容器管理对象生命周期，模块无需关心实例化细节。',
        ),
        CommonPitfalls(
          pitfalls: [
            '忘记在 dispose 中释放容器 — IoC 容器不会自动回收注册的对象',
            '循环依赖 — 容器无法自动检测循环依赖，需自行注意依赖方向',
            '过度使用全局单例 — 单例作用域应尽量缩小，避免状态污染',
          ],
        ),
        ExerciseCard(
          task: '注册一个 Transient 作用域的 Service，每次 resolve 都返回新实例，验证行为。',
          hint:
              '使用 container.registerTransient<T>(factory) 注册，多次 resolve 后比较引用是否相同。',
        ),
      ],
    );
  }
}
