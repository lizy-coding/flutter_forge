{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.shared.multi_window",
    "kind": "shared_layer",
    "package": "main_app",
    "path": "lib/shared/multi_window",
    "status": "ready"
  },
  "entrypoints": [
    "multi_window_manager.dart",
    "category_window_app.dart",
    "multi_window_route_filter.dart"
  ],
  "owns": [
    "desktop_window_lifecycle",
    "category_window_router",
    "module_route_filter"
  ],
  "depends": [
    "desktop_multi_window",
    "go_router",
    "module_registry",
    "app_router_module_table"
  ],
  "mutates": ["AI_ANALYSIS.md", "**/*.dart"],
  "files": [
    "multi_window_manager.dart",
    "category_window_app.dart",
    "multi_window_route_filter.dart"
  ],
  "apis": {
    "MultiWindowManager": {
      "role": "desktop_window_lifecycle",
      "public_api": [
        "MultiWindowManager.instance",
        "MultiWindowManager.isSupported",
        "createCategoryWindow(ModuleCategory)",
        "closeCategoryWindow(ModuleCategory)",
        "isCategoryOpen(ModuleCategory)"
      ]
    },
    "WindowArguments": {
      "role": "window_argument_parser",
      "public_api": ["WindowArguments.fromJson(Map<String,dynamic>)"]
    },
    "CategoryWindowApp": {
      "role": "category_window_router",
      "public_api": [
        "CategoryWindowApp(category:ModuleCategory)",
        "CategoryWindowApp.createRouter(ModuleCategory)"
      ]
    },
    "multi_window_route_filter": {
      "role": "module_route_filter",
      "public_api": [
        "filterModulesByCategory(List<ModuleEntry>,ModuleCategory)",
        "buildCategoryRoutes(List<ModuleEntry>)"
      ]
    }
  },
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": [
    "dart format .",
    "flutter analyze",
    "dart run flutterguard_cli:flutterguard scan --path . --fail-on high"
  ]
}
