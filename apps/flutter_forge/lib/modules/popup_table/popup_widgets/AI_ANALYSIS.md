{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.popup_table.popup_widgets",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/popup_table/popup_widgets",
    "status": "ready"
  },
  "route": "/popup-widgets",
  "category": "popup_table",
  "entrypoints": [
    "module_entry.dart",
    "module_root.dart",
    "widgets"
  ],
  "owns": [
    "module_entry",
    "module_ui",
    "module_docs"
  ],
  "depends": [
    "flutter_study_learning",
    "module_registry"
  ],
  "children": [],
  "analysis_parent": "lib/modules/popup_table/AI_ANALYSIS.md",
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
