import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/app_platform_snapshot.dart';
import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import '../module_registry/module_catalog_utils.dart';
import '../shared/multi_window/multi_window_manager.dart';

class CategoryHomePage extends StatelessWidget {
  const CategoryHomePage({
    super.key,
    required this.category,
    required this.modules,
    required this.platform,
    this.focusedWindow = false,
  });

  final ModuleCategory category;
  final List<ModuleEntry> modules;
  final AppPlatformSnapshot platform;
  final bool focusedWindow;

  @override
  Widget build(BuildContext context) {
    final categoryModules = modules
        .where((module) => module.category == category)
        .toList(growable: false);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        key: ValueKey('category-page:${category.name}'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Row(
                    children: [
                      Icon(category.icon, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.label,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text('${categoryModules.length} 个学习模块'),
                          ],
                        ),
                      ),
                      if (!focusedWindow &&
                          platform.hostFamily == AppHostFamily.desktop &&
                          MultiWindowManager.isSupported)
                        OutlinedButton.icon(
                          key: ValueKey('open-window:${category.name}'),
                          onPressed: () => MultiWindowManager.instance
                              .createCategoryWindow(category),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('在新窗口打开'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.crossAxisExtent >= 820 ? 2 : 1;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 260,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ModuleCard(
                      module: categoryModules[index],
                      platform: platform,
                    ),
                    childCount: categoryModules.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ModuleCard extends StatelessWidget {
  const ModuleCard({super.key, required this.module, required this.platform});

  final ModuleEntry module;
  final AppPlatformSnapshot platform;

  @override
  Widget build(BuildContext context) {
    final available = isModuleAvailable(module, platform);
    final concepts = module.concepts.take(3);
    return Card(
      child: InkWell(
        key: ValueKey('module:${module.path}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(module.path),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      module.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(module.difficulty.label),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                available ? module.subtitle : '当前平台暂不支持此模块',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final concept in concepts)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(concept),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '预计 ${module.estimatedMinutes} 分钟 · ${module.status.label}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
