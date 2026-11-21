import 'package:material_ui/material_ui.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

class FontPickerPage extends StatelessWidget {
  const FontPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LearningScaffold(
      title: '字体选择器',
      interactiveDemo: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Web 端保留字体学习入口，本地字体文件加载尚未验证。'),
        ),
      ),
      sections: [
        LearningObjectives(objectives: ['理解 Web 字体 fallback', '识别浏览器与桌面字体的差异']),
        CommonPitfalls(pitfalls: ['Web 系统字体受浏览器与操作系统影响', '未验证前不开放本地字体加载']),
      ],
    );
  }
}
