import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_entry.dart';
import 'navigation_session.dart';

bool matchesModule(ModuleEntry module, String query) => [
  module.title,
  module.subtitle,
  module.category.label,
  ...module.concepts,
].join(' ').toLowerCase().contains(query.trim().toLowerCase());

Future<void> showModuleSearch(
  BuildContext context,
  List<ModuleEntry> modules,
) async {
  final session = NavigationSessionScope.maybeOf(context);
  while (true) {
    if (!context.mounted) return;
    final selected = await showSearch<String?>(
      context: context,
      query: session?.searchQuery ?? '',
      delegate: ModuleSearchDelegate(modules, session: session),
    );
    if (selected == null || !context.mounted) return;
    await context.push(selected);
  }
}

class ModuleSearchDelegate extends SearchDelegate<String?> {
  ModuleSearchDelegate(this.modules, {this.session});

  final List<ModuleEntry> modules;
  final NavigationSession? session;

  @override
  String get searchFieldLabel => '搜索模块、概念或分类';

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
    session?.searchQuery = query;
    final matches = normalized.isEmpty
        ? const <ModuleEntry>[]
        : modules
              .where((module) => matchesModule(module, normalized))
              .toList(growable: false);
    if (normalized.isNotEmpty && matches.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () => query = '',
          child: const Text('没有匹配模块，清空搜索'),
        ),
      );
    }
    final results = ListView.builder(
      key: PageStorageKey('module-search:$normalized'),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final module = matches[index];
        return ListTile(
          title: Text(module.title),
          subtitle: Text(module.category.label),
          onTap: () {
            close(context, module.path);
          },
        );
      },
    );
    return session == null
        ? results
        : PageStorage(bucket: session!.pages, child: results);
  }
}
