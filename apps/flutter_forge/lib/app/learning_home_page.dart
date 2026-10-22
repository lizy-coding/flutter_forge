import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import 'module_search.dart';
import 'navigation_session.dart';
import 'workbench_history.dart';

class LearningHomePage extends StatelessWidget {
  const LearningHomePage({super.key, required this.modules});
  final List<ModuleEntry> modules;

  @override
  Widget build(BuildContext context) {
    final history = WorkbenchHistoryScope.maybeOf(context)?.recent ?? const [];
    final session = NavigationSessionScope.maybeOf(context);
    final recent = [
      for (final path in history)
        ...modules.where((module) => module.path == path),
    ];
    final content = ListView(
      key: const PageStorageKey('learning-home-scroll'),
      padding: const EdgeInsets.all(24),
      children: [
        Text('探索与查阅', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          '从一个问题或概念开始，找到可以运行的示例。',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('learning-home-search'),
          readOnly: true,
          onTap: () => showModuleSearch(context, modules),
          decoration: const InputDecoration(
            hintText: '搜索模块、概念或分类',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 28),
        Text('学习分类', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final category in ModuleCategory.values)
          Card(
            child: ListTile(
              key: ValueKey('learning-category:${category.name}'),
              leading: Icon(category.icon),
              title: Text(category.label),
              subtitle: Text(
                '${modules.where((module) => module.category == category).length} 个学习模块',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/category/${category.name}'),
            ),
          ),
        const SizedBox(height: 28),
        Text('最近访问', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('打开模块后，可以在这里快速找到它。'),
          ),
        for (final module in recent)
          Card(
            child: ListTile(
              key: ValueKey('recent:${module.path}'),
              leading: const Icon(Icons.history),
              title: Text(module.title),
              subtitle: Text(module.category.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(module.path),
            ),
          ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/about'),
            icon: const Icon(Icons.info_outline),
            label: const Text('关于 Flutter Forge'),
          ),
        ),
      ],
    );
    return KeyedSubtree(
      key: const ValueKey('learning-home'),
      child: session == null
          ? content
          : PageStorage(bucket: session.pages, child: content),
    );
  }
}
