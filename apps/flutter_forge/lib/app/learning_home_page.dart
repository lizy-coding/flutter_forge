import '../l10n/strings.dart';
import '../module_registry/app_platform_snapshot.dart';
import 'module_discovery_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import 'module_search.dart';
import 'navigation_session.dart';
import 'workbench_history.dart';

class LearningHomePage extends StatelessWidget {
  const LearningHomePage({super.key, required this.modules, this.platform});
  final List<ModuleEntry> modules;
  final AppPlatformSnapshot? platform;

  @override
  Widget build(BuildContext context) {
    final history = WorkbenchHistoryScope.maybeOf(context)?.recent ?? [];
    final session = NavigationSessionScope.maybeOf(context);
    final recent = [
      for (final path in history)
        ...modules.where((module) => module.path == path),
    ];
    final content = ListView(
      key: const PageStorageKey('learning-home-scroll'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          appStrings(context).explore,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          appStrings(context).homeIntro,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('learning-home-search'),
          readOnly: true,
          onTap: () => showModuleSearch(context, modules),
          decoration: InputDecoration(
            hintText: appStrings(context).searchHint,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          appStrings(context).categories,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final category in ModuleCategory.values)
          Card(
            child: ListTile(
              key: ValueKey('learning-category:${category.name}'),
              leading: Icon(category.icon),
              title: Text(category.labelFor(context)),
              subtitle: Text(
                appStrings(context).moduleCount(
                  modules.where((module) => module.category == category).length,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/category/${category.name}'),
            ),
          ),
        const SizedBox(height: 28),
        Text(
          appStrings(context).recent,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(appStrings(context).recentEmpty),
          ),
        for (final module in recent)
          Card(
            child: ListTile(
              key: ValueKey('recent:${module.path}'),
              leading: const Icon(Icons.history),
              title: Text(module.titleFor(context)),
              subtitle: Text(
                '${module.category.labelFor(context)} · ${appStrings(context).chineseExperiment}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(module.path),
            ),
          ),
        const SizedBox(height: 24),
        ModuleDiscoveryPanel(
          modules: modules,
          platform: platform ?? AppPlatformSnapshot.detect(),
          recentPaths: history,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/about'),
            icon: const Icon(Icons.info_outline),
            label: Text(appStrings(context).about),
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
