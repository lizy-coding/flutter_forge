import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  child: _CategoryHeader(
                    category: category,
                    moduleCount: categoryModules.length,
                    showWindowAction:
                        !focusedWindow &&
                        platform.hostFamily == AppHostFamily.desktop &&
                        MultiWindowManager.isSupported,
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

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.category,
    required this.moduleCount,
    required this.showWindowAction,
  });

  final ModuleCategory category;
  final int moduleCount;
  final bool showWindowAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: ValueKey('category-header:${category.name}'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryContainer.withValues(alpha: 0.72),
            colors.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(category.icon, color: colors.onPrimary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.label,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$moduleCount 个学习模块',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (showWindowAction) ...[
              const SizedBox(width: 16),
              Tooltip(
                message: '在独立窗口中专注学习这个分类',
                child: FilledButton.tonalIcon(
                  key: ValueKey('open-window:${category.name}'),
                  onPressed: () => MultiWindowManager.instance
                      .createCategoryWindow(category),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 19),
                  label: const Text('在新窗口打开'),
                ),
              ),
            ],
          ],
        ),
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
                  if (platform.isWeb)
                    IconButton(
                      key: ValueKey('open-tab:${module.path}'),
                      tooltip: '在新标签页打开',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => launchUrl(
                        Uri.base.resolve(module.path),
                        webOnlyWindowName: '_blank',
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 19),
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
