import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_entry.dart';

class ModuleSearchDelegate extends SearchDelegate<void> {
  ModuleSearchDelegate(this.modules);

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
            unawaited(context.push(module.path));
          },
        );
      },
    );
  }
}
