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
    "module_route_aggregation",
    "module_catalog_composition"
  ],
  "depends": [
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
