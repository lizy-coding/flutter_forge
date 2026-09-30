// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import 'package:go_router/go_router.dart';

import 'module_routes.dart';

class PopupListInteractionHome extends StatelessWidget {
  const PopupListInteractionHome({super.key});

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: '弹窗与列表交互',
      interactiveDemo: SizedBox(
        height: 250,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _NavCard(
              title: '弹窗组件',
              subtitle: '通过 Dialog 与 BottomSheet 选择动作，观察确认与取消结果',
              icon: Icons.open_in_browser,
              onTap: () => context.push(PopupListInteractionRoutes.popup),
            ),
            const SizedBox(height: 16),
            _NavCard(
              title: '列表交互',
              subtitle: '二维滚动表格，固定表头与行头，点击单元格进行编辑',
              icon: Icons.table_chart,
              onTap: () => context.push(PopupListInteractionRoutes.list),
            ),
          ],
        ),
      ),
      sections: [
        LearningObjectives(
          objectives: [
            '掌握 Flutter 弹窗组件（Dialog、BottomSheet、Overlay）的使用',
            '理解二维滚动表格的原理与实现',
            '学习弹窗与列表的协同交互方式',
          ],
        ),
        ConceptChips(
          concepts: [
            'Dialog',
            'BottomSheet',
            'Overlay',
            'ContextMenu',
            'TableView',
            '二维滚动',
          ],
        ),
        CodeSnippetCard(
          title: '弹窗与列表路由配置',
          code:
              "context.push(PopupListInteractionRoutes.popup);\n"
              "context.push(PopupListInteractionRoutes.list);",
          explanation: '模块内部使用 go_router 子路由管理多个演示页面。',
        ),
        CommonPitfalls(
          pitfalls: [
            'OverlayEntry 需在 dispose 时清理 — 否则会造成内存泄漏',
            'BottomSheet 在 ListView 中可能出现手势冲突 — 注意 GestureDetector 的嵌套',
          ],
        ),
        ExerciseCard(
          task: '在列表页的单元格编辑弹窗中增加校验，仅在确认时更新数据。',
          hint: '先保存编辑草稿，验证通过后使用 Navigator.pop 返回结果。',
        ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
