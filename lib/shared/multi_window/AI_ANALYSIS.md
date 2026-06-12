```json
{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "identity": "shared/multi_window",
    "path": "lib/shared/multi_window/",
    "category": "shared",
    "status": "ready"
  },
  "depends": [
    "module_registry/module_category.dart",
    "app/router/app_route_table.dart"
  ],
  "mutates": [],
  "owns": [
    "multi_window_manager.dart",
    "category_window_app.dart",
    "multi_window_route_filter.dart"
  ],
  "contracts": {
    "multi_window_manager": {
      "description": "桌面平台多窗口管理器，创建/关闭/管理分类子窗口",
      "entry": "MultiWindowManager",
      "public_api": [
        "MultiWindowManager.instance",
        "MultiWindowManager.isSupported",
        "createCategoryWindow(ModuleCategory)",
        "closeCategoryWindow(ModuleCategory)",
        "isCategoryOpen(ModuleCategory)",
        "WindowArguments.fromJson(Map<String, dynamic>)"
      ]
    },
    "category_window_app": {
      "description": "子窗口 MaterialApp.router，按分类过滤路由",
      "entry": "CategoryWindowApp",
      "public_api": [
        "CategoryWindowApp(category: ModuleCategory)",
        "CategoryWindowApp.createRouter(ModuleCategory)"
      ]
    },
    "multi_window_route_filter": {
      "description": "按分类过滤 ModuleEntry 列表和路由",
      "entry": "filterModulesByCategory",
      "public_api": [
        "filterModulesByCategory(List<ModuleEntry>, ModuleCategory)",
        "buildCategoryRoutes(List<ModuleEntry>)"
      ]
    }
  },
  "validation": {
    "lint": "dart format . && flutter analyze",
    "scan": "dart run flutterguard_cli:flutterguard scan --path . --fail-on high"
  }
}
```
