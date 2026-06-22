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
    "router/app_router.dart",
    "router/app_route_table.dart"
  ],
  "owns": [
    "material_app_router",
    "router"
  ],
  "depends": [
    "go_router",
    "module_registry",
    "modules"
  ],
  "children": [
    "router/AI_ANALYSIS.md"
  ],
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
