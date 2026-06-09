import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_route_table.dart';
import '../../module_registry/module_category.dart';
import '../../module_registry/module_entry.dart';
import 'multi_window_route_filter.dart';

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

  Color _difficultyColor(Difficulty d) {
    return switch (d) {
      Difficulty.beginner => Colors.green,
      Difficulty.intermediate => Colors.orange,
      Difficulty.advanced => Colors.red,
    };
  }

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
        itemBuilder: (context, index) {
          final module = modules[index];
          return ListTile(
            title: Row(
              children: [
                Expanded(child: Text(module.title)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _difficultyColor(module.difficulty)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    module.difficulty.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: _difficultyColor(module.difficulty),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(module.subtitle, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: module.concepts
                      .map(
                        (c) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(c, style: const TextStyle(fontSize: 10)),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 4),
                Text(
                  '预计 ${module.estimatedMinutes} 分钟 · ${module.status.label}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(_stripSlash(module.path)),
          );
        },
      ),
    );
  }

  String _stripSlash(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }
}
