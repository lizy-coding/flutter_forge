{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.module_registry",
    "kind": "registry_index",
    "package": "flutter_forge_app",
    "path": "lib/module_registry",
    "status": "active"
  },
  "entrypoints": [
    "module_entry.dart",
    "module_category.dart",
    "module_catalog_utils.dart"
  ],
  "owns": [
    "module_entry_model",
    "module_category_enum",
    "difficulty_enum",
    "module_status_enum",
    "module_catalog_filtering",
    "category_route_rebasing"
  ],
  "depends": [
    "flutter_material",
    "go_router"
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
