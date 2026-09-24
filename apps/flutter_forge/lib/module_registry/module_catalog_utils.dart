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

List<GoRoute> buildCategoryRoutes(
  List<ModuleEntry> modules,
  AppPlatformSnapshot platform, {
  required Widget Function(BuildContext, ModuleEntry) unsupportedBuilder,
}) {
  return [
    for (final module in modules)
      GoRoute(
        path: _stripLeadingSlash(module.path),
        builder: (context, state) => isModuleAvailable(module, platform)
            ? module.builder(context)
            : unsupportedBuilder(context, module),
        routes: isModuleAvailable(module, platform)
            ? _rebasedRoutes(module.routes)
            : const [],
      ),
  ];
}

String _stripLeadingSlash(String path) {
  return path.startsWith('/') ? path.substring(1) : path;
}

List<GoRoute> _rebasedRoutes(List<GoRoute> routes) {
  return routes.map((route) {
    final strippedPath = _stripLeadingSlash(route.path);
    return GoRoute(
      path: strippedPath,
      builder: route.builder,
      routes: route.routes,
    );
  }).toList();
}
