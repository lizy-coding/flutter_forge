import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'module_routes.dart';

class PopupListInteractionHome extends StatelessWidget {
  const PopupListInteractionHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('弹窗与列表交互'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NavCard(
            title: '弹窗组件',
            subtitle: 'AlertDialog、BottomSheet、Overlay、ContextMenu 等弹窗类型',
            icon: Icons.open_in_browser,
            onTap: () => context.push(PopupListInteractionRoutes.popup),
          ),
          const SizedBox(height: 16),
          _NavCard(
            title: '列表交互',
            subtitle: '二维滚动表格，固定表头与行头',
            icon: Icons.table_chart,
            onTap: () => context.push(PopupListInteractionRoutes.list),
          ),
        ],
      ),
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
