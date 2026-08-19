import 'package:go_router/go_router.dart';

import 'module_category.dart';
import 'module_entry.dart';

List<ModuleEntry> filterModulesByCategory(
  List<ModuleEntry> allModules,
  ModuleCategory category,
) {
  return allModules.where((module) => module.category == category).toList();
}

List<GoRoute> buildCategoryRoutes(List<ModuleEntry> modules) {
  return [
    for (final module in modules)
      GoRoute(
        path: _stripLeadingSlash(module.path),
        builder: (context, state) => module.builder(context),
        routes: _rebasedRoutes(module.routes),
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
