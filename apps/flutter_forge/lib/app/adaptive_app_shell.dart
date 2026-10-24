import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import 'navigation_policy.dart';
import 'module_search.dart';
import '../module_registry/app_platform_snapshot.dart';
import 'desktop_workbench_shell.dart';
import 'desktop_window_host.dart';
import 'forge_bubble_navigation.dart';
import 'forge_nav_tile.dart';
import 'forge_selectable_list.dart';
import 'theme/theme_mode_button.dart';
import 'theme/forge_theme_tokens.dart';
import 'theme/forge_glass.dart';
import 'workbench_history.dart';

class AdaptiveAppShell extends StatefulWidget {
  const AdaptiveAppShell({
    super.key,
    required this.modules,
    required this.child,
    required this.location,
    this.platform,
  });

  final List<ModuleEntry> modules;
  final Widget child;
  final String location;
  final AppPlatformSnapshot? platform;

  @override
  State<AdaptiveAppShell> createState() => _AdaptiveAppShellState();
}

class _AdaptiveAppShellState extends State<AdaptiveAppShell> {
  bool _sidebarExpanded = true;
  int _selectedIndex() {
    if (widget.location == '/') return 0;
    for (var index = 0; index < ModuleCategory.values.length; index++) {
      final category = ModuleCategory.values[index];
      if (widget.location == '/category/${category.name}' ||
          widget.modules.any(
            (module) =>
                module.category == category &&
                widget.location.startsWith(module.path),
          )) {
        return index + 1;
      }
    }
    return 0;
  }

  void _goTo(int index) {
    if (index == 0) {
      context.go('/');
      return;
    }
    context.go('/category/${ModuleCategory.values[index - 1].name}');
  }

  Future<void> _showSearch() async {
    await showModuleSearch(context, widget.modules);
  }

  @override
  void didUpdateWidget(AdaptiveAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) _recordRecent();
  }

  @override
  void initState() {
    super.initState();
    _recordRecent();
  }

  void _recordRecent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final module in widget.modules) {
        if (widget.location == module.path ||
            widget.location.startsWith('${module.path}/')) {
          WorkbenchHistoryScope.maybeOf(context)?.record(module.path);
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final platform = widget.platform ?? AppPlatformSnapshot.detect();
    if (platform.hostFamily == AppHostFamily.desktop) {
      return DesktopWorkbenchShell(
        modules: widget.modules,
        location: widget.location,
        platform: platform,
        child: widget.child,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = NavigationPolicy.layoutFor(
          width: constraints.maxWidth,
          sidebarExpanded: _sidebarExpanded,
        );
        final compact = layout == AppNavigationLayout.compact;
        return CallbackShortcuts(
          bindings: {
            if (!isTeachingLocation(widget.location, widget.modules))
              const SingleActivator(LogicalKeyboardKey.slash): _showSearch,
            const SingleActivator(LogicalKeyboardKey.keyK, control: true):
                _showSearch,
            const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
                _showSearch,
            if (context.forgeColors.desktop)
              const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
                  _showSearch,
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              key: const ValueKey('adaptive-app-shell'),
              backgroundColor: context.forgeColors.desktop
                  ? Colors.transparent
                  : null,
              appBar:
                  compact &&
                      (widget.location == '/' ||
                          widget.location == '/about' ||
                          widget.location.startsWith('/category/'))
                  ? AppBar(
                      backgroundColor: context.forgeColors.glass
                          ? Colors.transparent
                          : null,
                      flexibleSpace: context.forgeColors.glass
                          ? const ForgeGlassSurface(
                              radius: 0,
                              refract: true,
                              child: SizedBox.expand(),
                            )
                          : null,
                      title: const Text('Flutter Forge'),
                      actions: [
                        const ThemeModeButton(),
                        IconButton(
                          tooltip: '搜索模块',
                          onPressed: _showSearch,
                          icon: const Icon(Icons.search),
                        ),
                      ],
                    )
                  : null,
              drawer: compact
                  ? NavigationDrawer(
                      selectedIndex: context.forgeColors.glass
                          ? null
                          : _selectedIndex(),
                      onDestinationSelected: (index) {
                        Navigator.of(context).pop();
                        _goTo(index);
                      },
                      children: context.forgeColors.glass
                          ? [
                              ForgeBubbleNavigation(
                                destinations: _destinations,
                                selectedIndex: _selectedIndex(),
                                destinationKey: (index) => ValueKey(
                                  'category-drawer:${index == 0 ? 'home' : ModuleCategory.values[index - 1].name}',
                                ),
                                onDestinationSelected: (index) {
                                  Navigator.of(context).pop();
                                  _goTo(index);
                                },
                              ),
                            ]
                          : _destinations
                                .map(
                                  (destination) => NavigationDrawerDestination(
                                    key: ValueKey(
                                      'category-drawer:${_destinations.indexOf(destination) == 0 ? 'home' : ModuleCategory.values[_destinations.indexOf(destination) - 1].name}',
                                    ),
                                    icon: Icon(destination.icon),
                                    label: Text(destination.label),
                                  ),
                                )
                                .toList(),
                    )
                  : null,
              body: compact
                  ? widget.child
                  : Row(
                      children: [
                        if (layout == AppNavigationLayout.sidebar)
                          _Sidebar(
                            selectedIndex: _selectedIndex(),
                            onDestinationSelected: _goTo,
                            onSearch: _showSearch,
                            onCollapse: () =>
                                setState(() => _sidebarExpanded = false),
                          )
                        else
                          _navigationSurface(
                            context,
                            context.forgeColors.glass
                                ? _BubbleRail(
                                    selectedIndex: _selectedIndex(),
                                    onDestinationSelected: _goTo,
                                    onSearch: _showSearch,
                                    onExpand: () =>
                                        setState(() => _sidebarExpanded = true),
                                  )
                                : NavigationRail(
                                    key: const ValueKey('navigation-rail'),
                                    selectedIndex: _selectedIndex(),
                                    onDestinationSelected: _goTo,
                                    leading: Column(
                                      children: [
                                        IconButton(
                                          tooltip: '展开侧栏',
                                          onPressed: () => setState(
                                            () => _sidebarExpanded = true,
                                          ),
                                          icon: const Icon(Icons.menu_open),
                                        ),
                                        IconButton(
                                          tooltip: '搜索模块',
                                          onPressed: _showSearch,
                                          icon: const Icon(Icons.search),
                                        ),
                                        const ThemeModeButton(),
                                      ],
                                    ),
                                    destinations: _destinations
                                        .map(
                                          (destination) =>
                                              NavigationRailDestination(
                                                icon: Icon(destination.icon),
                                                label: Text(destination.label),
                                              ),
                                        )
                                        .toList(),
                                  ),
                          ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: ColoredBox(
                            color: context.forgeColors.desktop
                                ? context.forgeColors.canvas
                                : Colors.transparent,
                            child: widget.child,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

Widget _navigationSurface(BuildContext context, Widget child) =>
    context.forgeColors.glass
    ? ForgeGlassSurface(radius: 0, refract: true, child: child)
    : child;

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onSearch,
    required this.onCollapse,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onSearch;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('expanded-sidebar'),
      width: context.forgeColors.desktop ? 224 : 264,
      child: _navigationSurface(
        context,
        Material(
          color: context.forgeColors.sidebar,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (context.forgeColors.desktop)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Flutter Forge',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const ThemeModeButton(),
                      ],
                    ),
                  )
                else
                  ListTile(
                    title: const Text('Flutter Forge'),
                    subtitle: const Text('可交互的 Flutter 学习现场'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ThemeModeButton(),
                        IconButton(
                          tooltip: '收起侧栏',
                          onPressed: onCollapse,
                          icon: const Icon(Icons.menu_open),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: TextField(
                    key: const ValueKey('sidebar-search'),
                    readOnly: true,
                    onTap: onSearch,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: '搜索模块或概念',
                      suffixIconConstraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 36,
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(10),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '/',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: context.forgeColors.glass
                      ? SingleChildScrollView(
                          primary: false,
                          child: ForgeBubbleNavigation(
                            destinations: _destinations,
                            selectedIndex: selectedIndex,
                            onDestinationSelected: onDestinationSelected,
                            destinationKey: (index) =>
                                ValueKey('sidebar-destination:$index'),
                          ),
                        )
                      : ForgeSelectableList(
                          itemCount: _destinations.length,
                          selectedIndex: selectedIndex,
                          onActivate: onDestinationSelected,
                          itemBuilder: (context, index, keyboardActive) {
                            final destination = _destinations[index];
                            final native = context.forgeColors.desktop;
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: native ? 8 : 0,
                                vertical: native ? 2 : 0,
                              ),
                              child: ForgeNavTile(
                                key: ValueKey('sidebar-destination:$index'),
                                label: destination.label,
                                icon: destination.icon,
                                keyboardActive: keyboardActive,
                                selected: index == selectedIndex,
                                onTap: () => onDestinationSelected(index),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final List<ForgeNavigationDestination> _destinations = [
  const ForgeNavigationDestination('探索与查阅', Icons.home_outlined),
  for (final category in ModuleCategory.values)
    ForgeNavigationDestination(category.label, category.icon),
];

class _BubbleRail extends StatelessWidget {
  const _BubbleRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onSearch,
    required this.onExpand,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onSearch;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('navigation-rail'),
      width: 80,
      child: SafeArea(
        child: Column(
          children: [
            IconButton(
              tooltip: '展开侧栏',
              onPressed: onExpand,
              icon: const Icon(Icons.menu_open),
            ),
            IconButton(
              tooltip: '搜索模块',
              onPressed: onSearch,
              icon: const Icon(Icons.search),
            ),
            const ThemeModeButton(),
            Expanded(
              child: SingleChildScrollView(
                primary: false,
                child: ForgeBubbleNavigation(
                  destinations: _destinations,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  showLabels: false,
                  destinationKey: (index) =>
                      ValueKey('rail-destination:$index'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
