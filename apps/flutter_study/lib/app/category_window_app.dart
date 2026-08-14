import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_catalog_utils.dart';
import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import 'module_home_page.dart';
import 'router/app_route_table.dart';

class CategoryWindowApp extends StatelessWidget {
  const CategoryWindowApp({super.key, required this.category});

  final ModuleCategory category;

  static GoRouter createRouter(ModuleCategory category) {
    final modules = filterModulesByCategory(AppRouteTable.modules, category);
    final childRoutes = buildCategoryRoutes(modules);

    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              CategoryHomePage(category: category, modules: modules),
          routes: childRoutes,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: CategoryWindowApp.createRouter(category),
      title: category.label,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}

class CategoryHomePage extends StatelessWidget {
  const CategoryHomePage({
    super.key,
    required this.category,
    required this.modules,
  });

  final ModuleCategory category;
  final List<ModuleEntry> modules;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.label),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: modules.length,
        itemBuilder: (context, index) => ModuleListTile(module: modules[index]),
      ),
    );
  }
}
