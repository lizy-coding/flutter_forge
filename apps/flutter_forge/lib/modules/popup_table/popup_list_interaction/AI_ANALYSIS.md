{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.popup_table.popup_list_interaction",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/popup_table/popup_list_interaction",
    "status": "ready"
  },
  "route": "/popup-list-interaction",
  "category": "popup_table",
  "entrypoints": [
    "module_entry.dart",
    "module_root.dart",
    "module_routes.dart",
    "pages"
  ],
  "owns": [
    "module_entry",
    "module_ui",
    "module_docs"
  ],
  "depends": [
    "flutter_study_learning",
    "module_registry",
    "go_router"
  ],
  "children": [],
  "analysis_parent": "lib/modules/popup_table/AI_ANALYSIS.md",
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
