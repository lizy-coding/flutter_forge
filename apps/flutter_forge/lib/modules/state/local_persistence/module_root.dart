import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import 'services/preferences_service.dart';
import 'state/persistence_demo_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.preferences});

  final PreferencesService? preferences;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PersistenceDemoController _controller;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _controller = PersistenceDemoController(
      preferences: widget.preferences ?? SharedPreferencesPreferencesService(),
    )..load();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (!_controller.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (_noteController.text != _controller.noteText) {
          _noteController.value = TextEditingValue(
            text: _controller.noteText,
            selection: TextSelection.collapsed(
              offset: _controller.noteText.length,
            ),
          );
        }
        return LearningScaffold(
          title: '本地持久化',
          interactiveDemo: _buildDemo(context),
          sections: const [
            LearningObjectives(
              objectives: [
                '理解键值存储如何保存简单设置项',
                '掌握异步读取与加载态的状态恢复流程',
                '学会通过依赖注入隔离插件并测试持久化逻辑',
              ],
            ),
            ConceptChips(
              concepts: ['shared_preferences', '键值存储', '异步读取', '状态恢复', '测试替身'],
            ),
            CodeSnippetCard(
              title: '使用官方 mock 测试持久化',
              code:
                  "SharedPreferences.setMockInitialValues({'count': 42});\n"
                  "final prefs = await SharedPreferences.getInstance();",
              explanation: '官方 mock 机制让测试可以使用真实服务实现，而无需手写平台 fake。',
            ),
          ],
        );
      },
    );
  }

  Widget _buildDemo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '计数器：${_controller.count}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: _controller.increment,
              child: const Text('+1'),
            ),
            ElevatedButton(
              onPressed: _controller.decrement,
              child: const Text('-1'),
            ),
            OutlinedButton(
              onPressed: _controller.reset,
              child: const Text('重置'),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('启用声音'),
          value: _controller.soundEnabled,
          onChanged: _controller.updateSoundEnabled,
        ),
        TextField(
          controller: _noteController,
          onChanged: _controller.updateNoteText,
          decoration: const InputDecoration(
            labelText: '备注（自动保存）',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await _controller.clearAll();
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已清除全部本地数据')));
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('清除全部'),
        ),
      ],
    );
  }
}
