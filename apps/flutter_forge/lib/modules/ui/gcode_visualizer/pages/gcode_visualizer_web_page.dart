import 'package:material_ui/material_ui.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

class GcodeVisualizerPage extends StatelessWidget {
  const GcodeVisualizerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LearningScaffold(
      title: 'G-code 视觉化',
      interactiveDemo: _UnavailableDemo(),
      sections: [
        LearningObjectives(
          objectives: ['了解 G-code 轨迹视觉化', '识别 Web 与原生 GPU 能力边界'],
        ),
        CommonPitfalls(
          pitfalls: ['gcode_core 当前只验证 macOS GPU', '不能仅根据 Web 构建成功开放该模块'],
        ),
      ],
    );
  }
}

class _UnavailableDemo extends StatelessWidget {
  const _UnavailableDemo();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'G-code 视觉化当前不支持 Web。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
