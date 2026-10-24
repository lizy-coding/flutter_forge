import 'module_discovery_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/app_platform_snapshot.dart';
import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import 'forge_pressable_card.dart';
import 'module_quick_open.dart';
import 'workbench_history.dart';
import 'navigation_session.dart';

class WorkbenchHomePage extends StatelessWidget {
  const WorkbenchHomePage({
    super.key,
    required this.modules,
    required this.platform,
  });
  final List<ModuleEntry> modules;
  final AppPlatformSnapshot platform;

  @override
  Widget build(BuildContext context) {
    final paths =
        WorkbenchHistoryScope.maybeOf(context)?.recent ?? const <String>[];
    final byPath = {for (final module in modules) module.path: module};
    final recent = [
      for (final path in paths)
        if (byPath[path] case final module?) module,
    ];
    final session = NavigationSessionScope.maybeOf(context);
    final content = ListView(
      key: const PageStorageKey('workbench-home-scroll'),
      padding: const EdgeInsets.all(28),
      children: [
        ModuleDiscoveryPanel(
          modules: modules,
          platform: platform,
          recentPaths: paths,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '随时继续探索',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => showModuleQuickOpen(context, modules),
              icon: const Icon(Icons.search, size: 16),
              label: const Text('快速打开模块'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('最近访问', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('还没有访问记录，从下方分类或侧栏开始。'),
          ),
        for (final module in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ForgePressableCard(
              key: ValueKey('recent:${module.path}'),
              radius: 8,
              onTap: () => context.go(module.path),
              child: ListTile(
                leading: Icon(module.category.icon, size: 20),
                title: Text(module.title),
                subtitle: Text(module.category.label),
                trailing: const Icon(Icons.arrow_forward, size: 18),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text('学习分类', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final category in ModuleCategory.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ForgePressableCard(
              key: ValueKey('workbench-category:${category.name}'),
              radius: 8,
              onTap: () => context.go('/category/${category.name}'),
              child: ListTile(
                leading: Icon(category.icon, size: 20),
                title: Text(category.label),
                trailing: Text(
                  '${modules.where((module) => module.category == category).length} 个模块',
                ),
              ),
            ),
          ),
      ],
    );
    return KeyedSubtree(
      key: const ValueKey('workbench-home'),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: session == null
              ? content
              : PageStorage(bucket: session.pages, child: content),
        ),
      ),
    );
  }
}
