import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_catalog_utils.dart';
import '../module_registry/module_category.dart';
import '../module_registry/app_platform_snapshot.dart';
import 'module_home_page.dart';
import 'unsupported_module_page.dart';
import 'router/app_route_table.dart';

class CategoryWindowApp extends StatefulWidget {
  const CategoryWindowApp({
    super.key,
    required this.category,
    required this.platform,
  });

  final ModuleCategory category;
  final AppPlatformSnapshot platform;

  static GoRouter createRouter(
    ModuleCategory category,
    AppPlatformSnapshot platform,
  ) {
    final modules = filterModulesByCategory(AppRouteTable.modules, category);
    final childRoutes = buildCategoryRoutes(
      modules,
      platform,
      unsupportedBuilder: (_, module) =>
          UnsupportedModulePage(module: module, platform: platform),
    );

    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => CategoryHomePage(
            category: category,
            modules: modules,
            platform: platform,
            focusedWindow: true,
          ),
          routes: childRoutes,
        ),
      ],
    );
  }

  @override
  State<CategoryWindowApp> createState() => _CategoryWindowAppState();
}

class _CategoryWindowAppState extends State<CategoryWindowApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = CategoryWindowApp.createRouter(widget.category, widget.platform);
  }

  @override
  void didUpdateWidget(CategoryWindowApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.platform.platform != widget.platform.platform) {
      final previous = _router;
      _router = CategoryWindowApp.createRouter(
        widget.category,
        widget.platform,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: widget.category.label,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}
