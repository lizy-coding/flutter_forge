{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.state.local_persistence",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/state/local_persistence",
    "status": "ready"
  },
  "route": "/local-persistence",
  "category": "state",
  "entrypoints": [
    "module_entry.dart",
    "module_root.dart",
    "state"
  ],
  "owns": [
    "module_entry",
    "module_ui",
    "module_docs"
  ],
  "depends": [
    "flutter_study_learning",
    "shared_preferences",
    "module_registry"
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
