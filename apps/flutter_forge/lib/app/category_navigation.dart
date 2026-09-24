import 'package:flutter/material.dart';

import '../module_registry/app_platform_snapshot.dart';
import '../module_registry/module_catalog_utils.dart';
import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import '../shared/multi_window/multi_window_manager.dart';
import 'module_home_page.dart';

/// Selects the platform-appropriate way to open a module category.
///
/// Desktop hosts may create a separate window. Mobile and other hosts keep the
/// same content inside the current navigation stack.
class CategoryNavigation {
  const CategoryNavigation._();

  static Future<void> openInApp(
    BuildContext context, {
    required ModuleCategory category,
    required List<ModuleEntry> modules,
    required AppPlatformSnapshot platform,
  }) async {
    final filtered = filterModulesByCategory(modules, category);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CategoryHomePage(
          category: category,
          modules: filtered,
          platform: platform,
        ),
      ),
    );
  }

  static Future<String?> openInNewWindow(ModuleCategory category) =>
      MultiWindowManager.instance.createCategoryWindow(category);
}
