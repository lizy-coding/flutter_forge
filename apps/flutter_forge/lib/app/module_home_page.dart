import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/app_platform_snapshot.dart';
import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import '../module_registry/module_catalog_utils.dart';
import 'category_navigation.dart';
import 'navigation_policy.dart';
import 'app_platform_provider.dart';

class ModuleHomePage extends ConsumerWidget {
  const ModuleHomePage({super.key, required this.modules});

  final List<ModuleEntry> modules;

  void _openCategory(
    BuildContext context,
    ModuleCategory category,
    AppPlatformSnapshot platform,
  ) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      CategoryNavigation.open(
        context,
        category: category,
        modules: modules,
        platform: platform,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = ref.watch(appPlatformProvider);
    final useCategoryDrawer = NavigationPolicy.usesMobileCategoryDrawer(
      platform,
    );
    final categories = ModuleCategory.values
        .where(
          (category) => modules.any((module) => module.category == category),
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Flutter 学习实验室')),
      drawer: useCategoryDrawer
          ? Drawer(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Text(
                        '学习目录',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          for (final category in categories)
                            ListTile(
                              key: ValueKey('category-drawer:${category.name}'),
                              leading: const Icon(Icons.book_outlined),
                              title: Text(category.label),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () =>
                                  _openCategory(context, category, platform),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final categoryModules = modules
                .where((module) => module.category == category)
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          CategoryNavigation.modeFor(context, platform) ==
                                  CategoryNavigationMode.separateWindow
                              ? Icons.open_in_new
                              : Icons.chevron_right,
                          size: 20,
                        ),
                        tooltip: '打开分类',
                        onPressed: () => CategoryNavigation.open(
                          context,
                          category: category,
                          modules: modules,
                          platform: platform,
                        ),
                      ),
                    ],
                  ),
                ),
                ...categoryModules.map(
                  (module) =>
                      ModuleListTile(module: module, platform: platform),
                ),
                const Divider(height: 1),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ModuleListTile extends StatelessWidget {
  const ModuleListTile({
    super.key,
    required this.module,
    required this.platform,
  });

  final ModuleEntry module;
  final AppPlatformSnapshot platform;

  Color _difficultyColor(Difficulty difficulty) {
    return switch (difficulty) {
      Difficulty.beginner => Colors.green,
      Difficulty.intermediate => Colors.orange,
      Difficulty.advanced => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _difficultyColor(module.difficulty);
    final isAvailable = isModuleAvailable(module, platform);
    final textOpacity = isAvailable ? 1.0 : 0.55;

    return ListTile(
      key: ValueKey('module:${module.path}'),
      title: Row(
        children: [
          Expanded(
            child: Opacity(opacity: textOpacity, child: Text(module.title)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: difficultyColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              module.difficulty.label,
              style: TextStyle(
                fontSize: 11,
                color: difficultyColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAvailable ? module.subtitle : '当前平台暂不支持此模块',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: textOpacity),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: module.concepts
                .map(
                  (concept) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(concept, style: const TextStyle(fontSize: 10)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          Text(
            '预计 ${module.estimatedMinutes} 分钟 · ${module.status.label}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600.withValues(alpha: textOpacity),
            ),
          ),
        ],
      ),
      trailing: Icon(
        isAvailable ? Icons.chevron_right : Icons.block,
        color: isAvailable ? null : Colors.grey,
      ),
      onTap: () => context.push(module.path),
    );
  }
}
