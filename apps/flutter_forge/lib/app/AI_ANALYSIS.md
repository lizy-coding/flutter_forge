{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.app",
    "kind": "app_index",
    "package": "flutter_forge_app",
    "path": "lib/app",
    "status": "active"
  },
  "entrypoints": [
    "app.dart",
    "app_bootstrap.dart",
    "module_home_page.dart",
    "category_navigation.dart",
    "navigation_policy.dart",
    "category_window_app.dart",
    "router/app_router.dart",
    "router/app_route_table.dart"
  ],
  "owns": [
    "host_bootstrap",
    "material_app_router",
    "router",
    "module_home",
    "responsive_navigation_policy",
    "adaptive_category_navigation",
    "desktop_category_window_shell"
  ],
  "depends": [
    "go_router",
    "module_registry",
    "shared/multi_window",
    "modules"
  ],
  "children": [
    "router/AI_ANALYSIS.md"
  ],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
