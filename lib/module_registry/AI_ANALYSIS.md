{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "main_app.module_registry",
    "kind": "registry_index",
    "package": "main_app",
    "path": "lib/module_registry",
    "status": "active"
  },
  "entrypoints": [
    "module_entry.dart",
    "module_category.dart"
  ],
  "owns": [
    "module_entry_model",
    "module_category_enum",
    "difficulty_enum",
    "module_status_enum"
  ],
  "depends": [
    "flutter_material"
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
