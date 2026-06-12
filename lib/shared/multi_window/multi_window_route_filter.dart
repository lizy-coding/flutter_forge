import 'package:go_router/go_router.dart';

import '../../module_registry/module_category.dart';
import '../../module_registry/module_entry.dart';

List<ModuleEntry> filterModulesByCategory(
  List<ModuleEntry> allModules,
  ModuleCategory category,
) {
  return allModules.where((m) => m.category == category).toList();
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
  return routes.map((r) {
    final strippedPath = r.path.startsWith('/') ? r.path.substring(1) : r.path;
    return GoRoute(
      path: strippedPath,
      builder: r.builder,
      routes: r.routes,
    );
  }).toList();
}
