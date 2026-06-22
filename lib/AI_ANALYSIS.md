{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "main_app.lib",
    "kind": "source_index",
    "package": "main_app",
    "path": "lib",
    "status": "active"
  },
  "entrypoints": [
    "main.dart",
    "app/app.dart",
    "app/router/app_route_table.dart"
  ],
  "owns": [
    "app",
    "module_registry",
    "shared",
    "modules"
  ],
  "depends": [
    "flutter_sdk",
    "go_router",
    "flutter_riverpod"
  ],
  "children": [
    "app/AI_ANALYSIS.md",
    "module_registry/AI_ANALYSIS.md",
    "shared/AI_ANALYSIS.md",
    "modules/AI_ANALYSIS.md"
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
