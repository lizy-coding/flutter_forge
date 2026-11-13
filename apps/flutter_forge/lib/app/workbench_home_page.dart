import '../l10n/strings.dart';
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
    final paths = WorkbenchHistoryScope.maybeOf(context)?.recent ?? <String>[];
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
                appStrings(context).continueExploring,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => showModuleQuickOpen(context, modules),
              icon: const Icon(Icons.search, size: 16),
              label: Text(appStrings(context).quickOpenModule),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          appStrings(context).recent,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(appStrings(context).noHistory),
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
                title: Text(module.titleFor(context)),
                subtitle: Text(
                  '${module.category.labelFor(context)} · ${appStrings(context).chineseExperiment}',
                ),
                trailing: const Icon(Icons.arrow_forward, size: 18),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          appStrings(context).categories,
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
                title: Text(category.labelFor(context)),
                trailing: Text(
                  appStrings(context).moduleCount(
                    modules
                        .where((module) => module.category == category)
                        .length,
                  ),
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
