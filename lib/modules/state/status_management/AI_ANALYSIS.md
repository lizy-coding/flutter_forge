{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "main_app.modules.state.status_management",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/state/status_management",
    "status": "recommended"
  },
  "route": "/status-management",
  "category": "state",
  "entrypoints": [
    "module_entry.dart",
    "module_routes.dart",
    "pages",
    "widgets"
  ],
  "owns": [
    "module_entry",
    "module_ui",
    "module_docs"
  ],
  "depends": [
    "flutter_study_learning",
    "provider",
    "flutter_riverpod",
    "flutter_bloc",
    "module_registry",
    "go_router"
  ],
  "children": [],
  "analysis_parent": "lib/modules/state/AI_ANALYSIS.md",
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
