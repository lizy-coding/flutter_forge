{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.shared",
    "kind": "shared_index",
    "package": "flutter_forge_app",
    "path": "lib/shared",
    "status": "active"
  },
  "entrypoints": [
    "learning",
    "multi_window",
    "platform",
    "popup",
    "table"
  ],
  "owns": [
    "business_free_capabilities",
    "learning_templates",
    "desktop_window_lifecycle",
    "platform_boundaries",
    "popup_ownership",
    "reusable_table_view"
  ],
  "depends": [
    "desktop_multi_window",
    "packages/file_picker_bridge"
  ],
  "children": [
    "multi_window/AI_ANALYSIS.md",
    "platform/AI_ANALYSIS.md",
    "popup/AI_ANALYSIS.md",
    "table/AI_ANALYSIS.md"
  ],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
