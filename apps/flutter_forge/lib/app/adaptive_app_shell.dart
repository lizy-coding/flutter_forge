import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import 'navigation_policy.dart';
import 'module_search.dart';
import 'mac_desktop_host.dart';
import 'forge_bubble_navigation.dart';
import 'theme/theme_mode_button.dart';
import 'theme/forge_theme_tokens.dart';
import 'theme/forge_glass.dart';

class AdaptiveAppShell extends StatefulWidget {
  const AdaptiveAppShell({
    super.key,
    required this.modules,
    required this.child,
    required this.location,
  });

  final List<ModuleEntry> modules;
  final Widget child;
  final String location;

  @override
  State<AdaptiveAppShell> createState() => _AdaptiveAppShellState();
}

class _AdaptiveAppShellState extends State<AdaptiveAppShell> {
  bool _sidebarExpanded = true;
  ChangeNotifier? _nativeSidebar;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sidebar = MacDesktopScope.sidebarOf(context);
    if (sidebar == _nativeSidebar) return;
    _nativeSidebar?.removeListener(_toggleSidebar);
    _nativeSidebar = sidebar;
    _nativeSidebar?.addListener(_toggleSidebar);
  }

  void _toggleSidebar() => setState(() => _sidebarExpanded = !_sidebarExpanded);

  @override
  void dispose() {
    _nativeSidebar?.removeListener(_toggleSidebar);
    super.dispose();
  }

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
    await showSearch<void>(
      context: context,
      delegate: ModuleSearchDelegate(widget.modules),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = NavigationPolicy.layoutFor(
          width: constraints.maxWidth,
          sidebarExpanded: _sidebarExpanded,
        );
        final compact = layout == AppNavigationLayout.compact;
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.slash): _showSearch,
            if (context.forgeColors.nativeDesktop)
              const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
                  _showSearch,
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              key: const ValueKey('adaptive-app-shell'),
              backgroundColor: context.forgeColors.nativeDesktop
                  ? Colors.transparent
                  : null,
              appBar:
                  compact &&
                      (widget.location == '/' ||
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
                            color: context.forgeColors.nativeDesktop
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
      width: context.forgeColors.nativeDesktop ? 224 : 264,
      child: _navigationSurface(
        context,
        Material(
          color: context.forgeColors.sidebar,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (context.forgeColors.nativeDesktop)
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
                      hintText: '搜索模块标题',
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
                      : ListView.builder(
                          itemCount: _destinations.length,
                          itemBuilder: (context, index) {
                            final destination = _destinations[index];
                            final native = context.forgeColors.nativeDesktop;
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: native ? 8 : 0,
                                vertical: native ? 2 : 0,
                              ),
                              child: ListTile(
                                key: ValueKey('sidebar-destination:$index'),
                                dense: native,
                                minTileHeight: native ? 32 : null,
                                minLeadingWidth: native ? 18 : null,
                                horizontalTitleGap: native ? 8 : null,
                                shape: native
                                    ? RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      )
                                    : null,
                                selectedTileColor: native
                                    ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.12)
                                    : null,
                                selected: index == selectedIndex,
                                leading: Icon(
                                  destination.icon,
                                  size: native ? 18 : null,
                                ),
                                title: Text(destination.label),
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
  const ForgeNavigationDestination('创作者主页', Icons.home_outlined),
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
