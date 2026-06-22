{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "main_app.app.router",
    "kind": "router_index",
    "package": "main_app",
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
    "module_home_index"
  ],
  "depends": [
    "module_registry",
    "modules"
  ],
  "children": [],
  "contracts": {
    "no_natural_language": true,
    "index_only": true,
    "max_index_depth": 2,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": [
    "flutter analyze"
  ]
}
