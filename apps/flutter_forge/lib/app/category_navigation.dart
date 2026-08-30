import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../module_registry/module_catalog_utils.dart';
import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import '../shared/multi_window/multi_window_manager.dart';
import 'category_window_app.dart';
import 'navigation_policy.dart';

/// Selects the platform-appropriate way to open a module category.
///
/// Desktop hosts may create a separate window. Mobile and other hosts keep the
/// same content inside the current navigation stack.
class CategoryNavigation {
  const CategoryNavigation._();

  static CategoryNavigationMode modeFor(BuildContext context) {
    return NavigationPolicy.resolve(
      platform: defaultTargetPlatform,
      width: MediaQuery.sizeOf(context).width,
      multiWindowSupported: MultiWindowManager.isSupported,
    );
  }

  static Future<void> open(
    BuildContext context, {
    required ModuleCategory category,
    required List<ModuleEntry> modules,
  }) async {
    if (modeFor(context) == CategoryNavigationMode.separateWindow) {
      await MultiWindowManager.instance.createCategoryWindow(category);
      return;
    }

    if (!context.mounted) return;
    final filtered = filterModulesByCategory(modules, category);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CategoryHomePage(category: category, modules: filtered),
      ),
    );
  }
}
