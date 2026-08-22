{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.modules.basic",
    "kind": "module_category_index",
    "package": "flutter_forge_app",
    "path": "lib/modules/basic",
    "status": "active"
  },
  "entrypoints": [
    "tree_state",
    "microtask",
    "debounce_throttle"
  ],
  "owns": [
    "basic_mechanisms"
  ],
  "depends": [
    "module_registry",
    "flutter_study_learning"
  ],
  "children": [
    "tree_state/AI_ANALYSIS.md",
    "microtask/AI_ANALYSIS.md",
    "debounce_throttle/AI_ANALYSIS.md"
  ],
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
