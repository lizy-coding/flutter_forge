{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "main_app.modules.ui.download_animation",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/ui/download_animation",
    "status": "ready"
  },
  "route": "/download-animation",
  "category": "ui",
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
  "analysis_parent": "lib/modules/ui/AI_ANALYSIS.md",
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
