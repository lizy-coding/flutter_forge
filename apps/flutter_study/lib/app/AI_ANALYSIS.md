{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "main_app.app",
    "kind": "app_index",
    "package": "main_app",
    "path": "lib/app",
    "status": "active"
  },
  "entrypoints": [
    "app.dart",
    "app_bootstrap.dart",
    "module_home_page.dart",
    "category_navigation.dart",
    "category_window_app.dart",
    "router/app_router.dart",
    "router/app_route_table.dart"
  ],
  "owns": [
    "host_bootstrap",
    "material_app_router",
    "router",
    "module_home",
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
    "index_only": true,
    "max_index_depth": 2,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": [
    "flutter analyze"
  ]
}
