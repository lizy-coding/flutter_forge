import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_platform_snapshot.dart';
import 'module_category.dart';
import 'module_entry.dart';

List<ModuleEntry> filterModulesByCategory(
  List<ModuleEntry> allModules,
  ModuleCategory category,
) {
  return allModules.where((module) => module.category == category).toList();
}

bool isModuleAvailable(ModuleEntry module, AppPlatformSnapshot platform) =>
    module.isSupportedOn(platform);

List<ModuleEntry> availableModules(
  List<ModuleEntry> modules,
  AppPlatformSnapshot platform,
) {
  return modules
      .where((module) => isModuleAvailable(module, platform))
      .toList();
}

/// Builds guarded module routes for the main or a category navigator.
List<GoRoute> buildModuleRoutes(
  List<ModuleEntry> modules,
  AppPlatformSnapshot platform, {
  required Widget Function(BuildContext, ModuleEntry) unsupportedBuilder,
  bool nested = false,
}) {
  return [
    for (final module in modules)
      GoRoute(
        path: nested ? _stripLeadingSlash(module.path) : module.path,
        builder: (context, state) => isModuleAvailable(module, platform)
            ? module.builder(context)
            : unsupportedBuilder(context, module),
        routes: isModuleAvailable(module, platform)
            ? _rebasedRoutes(module.routes)
            : const [],
      ),
  ];
}

List<GoRoute> buildCategoryRoutes(
  List<ModuleEntry> modules,
  AppPlatformSnapshot platform, {
  required Widget Function(BuildContext, ModuleEntry) unsupportedBuilder,
}) => buildModuleRoutes(
  modules,
  platform,
  unsupportedBuilder: unsupportedBuilder,
  nested: true,
);

String _stripLeadingSlash(String path) {
  return path.startsWith('/') ? path.substring(1) : path;
}

List<RouteBase> _rebasedRoutes(List<RouteBase> routes) {
  return [
    for (final route in routes)
      if (route is GoRoute)
        GoRoute(
          path: _stripLeadingSlash(route.path),
          name: route.name,
          builder: route.builder,
          pageBuilder: route.pageBuilder,
          redirect: route.redirect,
          onExit: route.onExit,
          parentNavigatorKey: route.parentNavigatorKey,
          routes: _rebasedRoutes(route.routes),
        )
      else
        route,
  ];
}
