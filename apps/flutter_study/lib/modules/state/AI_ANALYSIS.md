{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "main_app.modules.state",
    "kind": "module_category_index",
    "package": "main_app",
    "path": "lib/modules/state",
    "status": "active"
  },
  "entrypoints": [
    "status_management",
    "flutter_ioc"
  ],
  "owns": [
    "state_management"
  ],
  "depends": [
    "provider",
    "flutter_riverpod",
    "flutter_bloc",
    "flutter_ioc_core"
  ],
  "children": [
    "status_management/AI_ANALYSIS.md",
    "flutter_ioc/AI_ANALYSIS.md"
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
