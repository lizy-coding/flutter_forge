import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_catalog_utils.dart';
import '../module_registry/module_category.dart';
import '../module_registry/app_platform_snapshot.dart';
import '../module_registry/app_platform_scope.dart';
import 'module_home_page.dart';
import 'unsupported_module_page.dart';
import 'router/app_route_table.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_controller.dart';
import 'theme/forge_glass.dart';
import 'desktop_window_host.dart';
import 'desktop_workbench_shell.dart';
import 'theme/app_theme_selection.dart';
import 'navigation_session.dart';

class CategoryWindowApp extends StatefulWidget {
  const CategoryWindowApp({
    super.key,
    required this.category,
    required this.platform,
    required this.themeController,
  });

  final ModuleCategory category;
  final AppPlatformSnapshot platform;
  final AppThemeController themeController;

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

    final routes = <RouteBase>[
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
    ];
    return GoRouter(
      initialLocation: '/',
      routes: platform.hostFamily == AppHostFamily.desktop
          ? [
              ShellRoute(
                builder: (context, state, child) => DesktopWorkbenchShell(
                  modules: modules,
                  location: state.uri.path,
                  platform: platform,
                  focusedCategory: category,
                  child: child,
                ),
                routes: routes,
              ),
            ]
          : routes,
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
    return AppPlatformScope(
      platform: widget.platform,
      child: NavigationSessionScope(
        child: AppThemeScope(
          controller: widget.themeController,
          child: ListenableBuilder(
            listenable: widget.themeController,
            builder: (context, _) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: _router,
              title: widget.category.label,
              theme: AppTheme.light(widget.themeController.palette),
              darkTheme: AppTheme.dark(widget.themeController.palette),
              highContrastTheme: AppTheme.light(AppThemePalette.graphiteForge),
              highContrastDarkTheme: AppTheme.dark(
                AppThemePalette.graphiteForge,
              ),
              themeMode: widget.themeController.themeMode,
              builder: (context, child) => DesktopWindowHost(
                platform: widget.platform,
                mainWindow: false,
                title: widget.category.label,
                router: _router,
                modules: filterModulesByCategory(
                  AppRouteTable.modules,
                  widget.category,
                ),
                themeMode: widget.themeController.themeMode,
                materialEnabled:
                    widget.themeController.palette ==
                    AppThemePalette.liquidGlass,
                child: ForgeThemeBackdrop(child: child!),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
