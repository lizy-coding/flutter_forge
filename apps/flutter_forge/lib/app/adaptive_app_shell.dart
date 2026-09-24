import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import 'navigation_policy.dart';

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
      delegate: _ModuleSearchDelegate(widget.modules),
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
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              key: const ValueKey('adaptive-app-shell'),
              appBar:
                  compact &&
                      (widget.location == '/' ||
                          widget.location.startsWith('/category/'))
                  ? AppBar(
                      title: const Text('Flutter Forge'),
                      actions: [
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
                      selectedIndex: _selectedIndex(),
                      onDestinationSelected: (index) {
                        Navigator.of(context).pop();
                        _goTo(index);
                      },
                      children: _destinations
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
                          NavigationRail(
                            key: const ValueKey('navigation-rail'),
                            selectedIndex: _selectedIndex(),
                            onDestinationSelected: _goTo,
                            leading: Column(
                              children: [
                                IconButton(
                                  tooltip: '展开侧栏',
                                  onPressed: () =>
                                      setState(() => _sidebarExpanded = true),
                                  icon: const Icon(Icons.menu_open),
                                ),
                                IconButton(
                                  tooltip: '搜索模块',
                                  onPressed: _showSearch,
                                  icon: const Icon(Icons.search),
                                ),
                              ],
                            ),
                            destinations: _destinations
                                .map(
                                  (destination) => NavigationRailDestination(
                                    icon: Icon(destination.icon),
                                    label: Text(destination.label),
                                  ),
                                )
                                .toList(),
                          ),
                        const VerticalDivider(width: 1),
                        Expanded(child: widget.child),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

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
      width: 264,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: const Text('Flutter Forge'),
              subtitle: const Text('可交互的 Flutter 学习现场'),
              trailing: IconButton(
                tooltip: '收起侧栏',
                onPressed: onCollapse,
                icon: const Icon(Icons.menu_open),
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
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
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
              child: ListView.builder(
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  final destination = _destinations[index];
                  return ListTile(
                    key: ValueKey('sidebar-destination:$index'),
                    selected: index == selectedIndex,
                    leading: Icon(destination.icon),
                    title: Text(destination.label),
                    onTap: () => onDestinationSelected(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon);

  final String label;
  final IconData icon;
}

final List<_Destination> _destinations = [
  const _Destination('创作者主页', Icons.home_outlined),
  for (final category in ModuleCategory.values)
    _Destination(category.label, category.icon),
];

class _ModuleSearchDelegate extends SearchDelegate<void> {
  _ModuleSearchDelegate(this.modules);

  final List<ModuleEntry> modules;

  @override
  String get searchFieldLabel => '搜索模块标题';

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: '清空搜索',
        onPressed: () => query = '',
        icon: const Icon(Icons.clear),
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: '返回',
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final matches = normalized.isEmpty
        ? const <ModuleEntry>[]
        : modules
              .where(
                (module) => module.title.toLowerCase().contains(normalized),
              )
              .toList(growable: false);
    if (normalized.isNotEmpty && matches.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () => query = '',
          child: const Text('没有匹配模块，清空搜索'),
        ),
      );
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final module = matches[index];
        return ListTile(
          title: Text(module.title),
          subtitle: Text(module.category.label),
          onTap: () {
            close(context, null);
            context.push(module.path);
          },
        );
      },
    );
  }
}
