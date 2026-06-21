{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "main_app.shared.multi_window",
    "kind": "shared_capability_index",
    "package": "main_app",
    "path": "lib/shared/multi_window",
    "status": "active"
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
    "module_registry"
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
