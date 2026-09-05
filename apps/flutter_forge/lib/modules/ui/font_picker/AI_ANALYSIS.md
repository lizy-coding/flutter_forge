{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.ui.font_picker",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/ui/font_picker",
    "status": "ready"
  },
  "route": "/font-picker",
  "category": "ui",
  "entrypoints": [
    "module_entry.dart",
    "module_root.dart",
    "module_routes.dart",
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
    "file_picker_bridge",
    "module_registry",
    "go_router"
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
