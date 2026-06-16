import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

import '../module_routes.dart';

/// 主页列出所有示例入口，便于在调试时快速跳转。
class DemoHomePage extends StatelessWidget {
  static const String _baseRoute = '/tree-state';

  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const demos = <_DemoLink>[
      _DemoLink(
        title: '基础 Widget 重建',
        subtitle: 'StatelessWidget vs StatefulWidget 重建行为',
        routeName: TreeStateRoutes.basicWidgets,
      ),
      _DemoLink(
        title: 'State 生命周期',
        subtitle: 'StatefulWidget 生命周期 + setState',
        routeName: TreeStateRoutes.stateLifecycle,
      ),
      _DemoLink(
        title: 'CustomPainter 渲染',
        subtitle: 'CustomPainter 渲染阶段日志',
        routeName: TreeStateRoutes.painterDemo,
      ),
      _DemoLink(
        title: 'RepaintBoundary',
        subtitle: '局部重绘与 RenderObject 隔离',
        routeName: TreeStateRoutes.repaintBoundary,
      ),
    ];

    return LearningScaffold(
      title: 'Flutter 三棵树 & 生命周期示例',
      interactiveDemo: SizedBox(
        height: 260,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '观察 Widget / Element / RenderObject 的关系以及生命周期日志',
                style: TextStyle(fontSize: 14),
              ),
            ),
            for (final demo in demos)
              ListTile(
                title: Text(demo.title),
                subtitle: Text(demo.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('$_baseRoute${demo.routeName}'),
              ),
          ],
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解 Widget、Element、RenderObject 三棵树的角色与关系',
            '掌握 StatefulWidget 生命周期回调顺序',
            '理解 RepaintBoundary 的局部重绘机制',
            '掌握 CustomPainter 渲染与 shouldRepaint 逻辑',
          ],
        ),
        ConceptChips(
          concepts: [
            'Widget 树',
            'Element 树',
            'RenderObject',
            '生命周期',
            'setState',
            'RepaintBoundary',
            'CustomPainter'
          ],
        ),
        CodeSnippetCard(
          title: '三棵树协作模式',
          code: '''// Widget 树 — 配置描述
Widget build(BuildContext context) =>
    Column(children: [Text('hello')]);

// Element 树 — 桥梁，管理 State
class _MyState extends State<MyWidget> {
  // State 附着在 Element 上，不被重建
}

// RenderObject 树 — 布局/绘制
// CustomPainter 在 paint 阶段触发''',
          explanation:
              'setState → Element 标记 dirty → build 新 Widget → 比对更新 RenderObject → 触发重绘',
        ),
        CommonPitfalls(
          pitfalls: [
            'Widget 不是界面本身，只是轻量级配置对象，每次 build 都会新建',
            '不要将可变状态直接放在 Widget 字段中，应放在 State 中',
            'CustomPainter 的 shouldRepaint 应正确实现，避免无意义重绘',
          ],
        ),
        ExerciseCard(
          task:
              '进入子页面观察 debugPrint 日志，理解每个生命周期方法何时被调用。尝试在不同子页面之间切换，观察 Element 树的复用与销毁。',
          hint: '在 iOS/Android 终端或 IDE 的 Run 面板查看 debugPrint 输出。',
        ),
      ],
    );
  }
}

class _DemoLink {
  final String title;
  final String subtitle;
  final String routeName;

  const _DemoLink({
    required this.title,
    required this.subtitle,
    required this.routeName,
  });
}
