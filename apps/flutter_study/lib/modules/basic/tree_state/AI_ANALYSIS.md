{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "main_app.modules.basic.tree_state",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/basic/tree_state",
    "status": "recommended"
  },
  "route": "/tree-state",
  "category": "basic",
  "entrypoints": [
    "module_entry.dart",
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
  "analysis_parent": "lib/modules/basic/AI_ANALYSIS.md",
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
