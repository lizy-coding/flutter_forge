{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.ui.adsorption_line",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/ui/adsorption_line",
    "status": "ready"
  },
  "route": "/adsorption-line",
  "category": "ui",
  "entrypoints": [
    "module_entry.dart",
    "pages",
    "widgets",
    "state"
  ],
  "owns": [
    "module_entry",
    "module_ui",
    "module_docs"
  ],
  "depends": [
    "shared_learning",
    "provider",
    "module_registry"
  ],
  "children": [],
  "analysis_parent": "lib/modules/ui/AI_ANALYSIS.md",
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
