import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_forge_app/module_registry/module_catalog_utils.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_forge_app/module_registry/module_entry.dart';

void main() {
  ModuleEntry createModule({
    required String path,
    required ModuleCategory category,
    List<GoRoute> routes = const [],
    Set<TargetPlatform>? supportedPlatforms,
  }) {
    return ModuleEntry(
      title: path,
      path: path,
      subtitle: 'test',
      category: category,
      difficulty: Difficulty.beginner,
      concepts: const ['test'],
      estimatedMinutes: 1,
      status: ModuleStatus.ready,
      builder: (_) => const SizedBox.shrink(),
      routes: routes,
      supportedPlatforms: supportedPlatforms,
    );
  }

  test('filters modules without changing catalog order', () {
    final modules = [
      createModule(path: '/basic-a', category: ModuleCategory.basic),
      createModule(path: '/ui-a', category: ModuleCategory.ui),
      createModule(path: '/basic-b', category: ModuleCategory.basic),
    ];

    final filtered = filterModulesByCategory(modules, ModuleCategory.basic);

    expect(filtered.map((module) => module.path), ['/basic-a', '/basic-b']);
  });

  test('rebases module and child paths for a category window', () {
    final modules = [
      createModule(
        path: '/basic-a',
        category: ModuleCategory.basic,
        routes: [
          GoRoute(
            path: '/details',
            builder: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    ];

    final routes = buildCategoryRoutes(modules);

    expect(routes.single.path, 'basic-a');
    expect((routes.single.routes.single as GoRoute).path, 'details');
  });

  test('platform-neutral modules are available by default', () {
    final module = createModule(
      path: '/platform-neutral',
      category: ModuleCategory.basic,
    );

    expect(isModuleAvailable(module, TargetPlatform.android), isTrue);
    expect(isModuleAvailable(module, TargetPlatform.windows), isTrue);
  });

  test('platform-restricted modules only match declared platforms', () {
    final module = createModule(
      path: '/macos-only',
      category: ModuleCategory.platform,
      supportedPlatforms: {TargetPlatform.macOS},
    );

    expect(isModuleAvailable(module, TargetPlatform.macOS), isTrue);
    expect(isModuleAvailable(module, TargetPlatform.windows), isFalse);
    expect(availableModules([module], TargetPlatform.windows), isEmpty);
  });

  test('unavailable modules are excluded from category routes', () {
    final module = createModule(
      path: '/windows-only',
      category: ModuleCategory.platform,
      supportedPlatforms: {TargetPlatform.windows},
    );

    expect(buildCategoryRoutes([module]), isEmpty);
  });
}
