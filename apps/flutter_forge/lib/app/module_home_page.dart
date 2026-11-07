import '../l10n/strings.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../module_registry/app_platform_snapshot.dart';
import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import '../module_registry/module_catalog_utils.dart';
import '../shared/multi_window/multi_window_manager.dart';
import 'forge_pressable_card.dart';
import 'theme/forge_theme_tokens.dart';
import 'navigation_session.dart';

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
    final session = NavigationSessionScope.maybeOf(context);
    final scrollView = CustomScrollView(
      key: PageStorageKey('category-scroll:${category.name}'),
      slivers: _slivers(context, categoryModules),
    );
    return ColoredBox(
      key: ValueKey('category-page:${category.name}'),
      color: context.forgeColors.glass
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      child: session == null
          ? scrollView
          : PageStorage(bucket: session.pages, child: scrollView),
    );
  }

  List<Widget> _slivers(
    BuildContext context,
    List<ModuleEntry> categoryModules,
  ) => [
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
  ];
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appStrings(context).openWindowFailed)),
        );
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
                    widget.category.labelFor(context),
                    style:
                        (context.forgeColors.desktop
                                ? Theme.of(context).textTheme.titleLarge
                                : Theme.of(context).textTheme.headlineSmall)
                            ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appStrings(context).moduleCount(widget.moduleCount),
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
                message: appStrings(context).focusCategory,
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
                  label: Text(
                    _opening
                        ? appStrings(context).opening
                        : appStrings(context).newWindow,
                  ),
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
    final concepts = module.conceptsFor(context).take(3);
    final desktop = platform.hostFamily == AppHostFamily.desktop;
    return ForgePressableCard(
      key: ValueKey('module:${module.path}'),
      radius: desktop ? 8 : 12,
      onTap: () {
        if (desktop) {
          context.go(module.path);
        } else {
          unawaited(context.push(module.path));
        }
      },
      child: desktop
          ? ListTile(
              minVerticalPadding: 12,
              leading: Icon(module.category.icon, size: 20),
              title: Text(module.titleFor(context)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    available
                        ? module.subtitleFor(context)
                        : appStrings(context).unsupported,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(appStrings(context).chineseExperiment),
                ],
              ),
              isThreeLine: true,
              trailing: Text(
                '${module.difficulty.labelFor(context)} · ${appStrings(context).minutes(module.estimatedMinutes)}',
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          module.titleFor(context),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(module.difficulty.labelFor(context)),
                      ),
                      if (platform.isWeb)
                        IconButton(
                          key: ValueKey('open-tab:${module.path}'),
                          tooltip: appStrings(context).newTab,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => launchUrl(
                            Uri.base.replace(fragment: module.path),
                            webOnlyWindowName: '_blank',
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 19),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    available
                        ? module.subtitleFor(context)
                        : appStrings(context).unsupported,
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
                  Text(appStrings(context).chineseExperiment),
                  Text(
                    appStrings(context).estimatedTime(
                      module.estimatedMinutes,
                      module.status.labelFor(context),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
    );
  }
}
