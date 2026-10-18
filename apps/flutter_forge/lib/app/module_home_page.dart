import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../module_registry/app_platform_snapshot.dart';
import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import '../module_registry/module_catalog_utils.dart';
import '../shared/multi_window/multi_window_manager.dart';
import 'theme/forge_glass.dart';
import 'theme/forge_theme_tokens.dart';

class CategoryHomePage extends StatelessWidget {
  const CategoryHomePage({
    super.key,
    required this.category,
    required this.modules,
    required this.platform,
    this.focusedWindow = false,
    this.openCategoryWindow,
  });

  final ModuleCategory category;
  final List<ModuleEntry> modules;
  final AppPlatformSnapshot platform;
  final bool focusedWindow;
  final Future<String?> Function(ModuleCategory)? openCategoryWindow;

  @override
  Widget build(BuildContext context) {
    final categoryModules = modules
        .where((module) => module.category == category)
        .toList(growable: false);
    return ColoredBox(
      color: context.forgeColors.glass
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
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
                    key: ValueKey('category-window-action:${category.name}'),
                    category: category,
                    moduleCount: categoryModules.length,
                    openCategoryWindow: openCategoryWindow,
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
                final columns =
                    constraints.crossAxisExtent >= 820 &&
                        MediaQuery.textScalerOf(context).scale(14) <= 17
                    ? 2
                    : 1;
                if (columns == 1 || context.forgeColors.desktop) {
                  return SliverList.builder(
                    itemCount: categoryModules.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ModuleCard(
                        module: categoryModules[index],
                        platform: platform,
                      ),
                    ),
                  );
                }
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

class _CategoryHeader extends StatefulWidget {
  const _CategoryHeader({
    super.key,
    required this.category,
    required this.moduleCount,
    required this.showWindowAction,
    this.openCategoryWindow,
  });

  final ModuleCategory category;
  final int moduleCount;
  final bool showWindowAction;
  final Future<String?> Function(ModuleCategory)? openCategoryWindow;

  @override
  State<_CategoryHeader> createState() => _CategoryHeaderState();
}

class _CategoryHeaderState extends State<_CategoryHeader> {
  bool _opening = false;

  Future<void> _openWindow() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final open =
          widget.openCategoryWindow ??
          MultiWindowManager.instance.createCategoryWindow;
      await open(widget.category);
    } catch (error) {
      debugPrint('[category-window] open failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('打开分类窗口失败，请重试。')));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: ValueKey('category-header:${widget.category.name}'),
      decoration: BoxDecoration(
        color: context.forgeColors.desktop
            ? colors.surface.withValues(
                alpha: context.forgeColors.glass ? 0.72 : 1,
              )
            : null,
        gradient: context.forgeColors.desktop
            ? null
            : LinearGradient(
                colors: [
                  colors.primaryContainer.withValues(alpha: 0.72),
                  context.forgeColors.glass
                      ? colors.surfaceContainerHigh.withValues(alpha: 0.5)
                      : colors.surfaceContainerHigh,
                ],
              ),
        borderRadius: BorderRadius.circular(
          context.forgeColors.desktop ? 8 : 24,
        ),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: context.forgeColors.desktop ? 36 : 56,
              height: context.forgeColors.desktop ? 36 : 56,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(
                  context.forgeColors.desktop ? 8 : 18,
                ),
              ),
              child: Icon(
                widget.category.icon,
                color: colors.onPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.category.label,
                    style:
                        (context.forgeColors.desktop
                                ? Theme.of(context).textTheme.titleLarge
                                : Theme.of(context).textTheme.headlineSmall)
                            ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.moduleCount} 个学习模块',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showWindowAction) ...[
              const SizedBox(width: 16),
              Tooltip(
                message: '在独立窗口中专注学习这个分类',
                child: FilledButton.tonalIcon(
                  key: ValueKey('open-window:${widget.category.name}'),
                  onPressed: _opening ? null : () => unawaited(_openWindow()),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                  ),
                  icon: _opening
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.open_in_new_rounded, size: 19),
                  label: Text(_opening ? '正在打开…' : '在新窗口打开'),
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
    if (platform.hostFamily == AppHostFamily.desktop) {
      return ForgeShellSurface(
        radius: 8,
        child: ListTile(
          key: ValueKey('module:${module.path}'),
          minVerticalPadding: 12,
          leading: Icon(module.category.icon, size: 20),
          title: Text(module.title),
          subtitle: Text(
            available ? module.subtitle : '当前平台暂不支持此模块',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${module.difficulty.label} · ${module.estimatedMinutes} 分钟',
          ),
          onTap: () => context.go(module.path),
        ),
      );
    }
    return ForgeCard(
      child: InkWell(
        key: ValueKey('module:${module.path}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (platform.hostFamily == AppHostFamily.desktop) {
            context.go(module.path);
          } else {
            unawaited(context.push(module.path));
          }
        },
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
