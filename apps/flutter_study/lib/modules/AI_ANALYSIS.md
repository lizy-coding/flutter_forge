{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "main_app.modules",
    "kind": "modules_index",
    "package": "main_app",
    "path": "lib/modules",
    "status": "active"
  },
  "entrypoints": [
    "basic",
    "async",
    "state",
    "ui",
    "popup_table",
    "platform"
  ],
  "owns": [
    "learning_module_categories",
    "route_registered_modules"
  ],
  "depends": [
    "module_registry",
    "flutter_study_learning"
  ],
  "children": [
    "basic/AI_ANALYSIS.md",
    "async/AI_ANALYSIS.md",
    "state/AI_ANALYSIS.md",
    "ui/AI_ANALYSIS.md",
    "popup_table/AI_ANALYSIS.md",
    "platform/AI_ANALYSIS.md"
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
