{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.app.router",
    "kind": "router_index",
    "package": "flutter_forge_app",
    "path": "lib/app/router",
    "status": "active"
  },
  "entrypoints": [
    "app_router.dart",
    "app_route_table.dart"
  ],
  "owns": [
    "go_router_root",
    "adaptive_shell_route",
    "creator_home_route",
    "category_route",
    "stable_guarded_module_routes",
    "module_route_aggregation",
    "module_catalog_composition"
  ],
  "depends": [
    "app/adaptive_app_shell",
    "app/creator_home_page",
    "app/module_home_page",
    "module_registry",
    "modules"
  ],
  "children": [],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
