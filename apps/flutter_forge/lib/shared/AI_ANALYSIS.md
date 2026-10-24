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
    "table",
    "workflows"
  ],
  "owns": [
    "business_free_capabilities",
    "learning_templates",
    "desktop_window_lifecycle",
    "platform_boundaries",
    "popup_ownership",
    "reusable_table_view",
    "workflow_control_transport"
  ],
  "depends": [
    "desktop_multi_window",
    "packages/file_picker_bridge",
    "dio"
  ],
  "children": [
    "multi_window/AI_ANALYSIS.md",
    "platform/AI_ANALYSIS.md",
    "popup/AI_ANALYSIS.md",
    "table/AI_ANALYSIS.md",
    "workflows/AI_ANALYSIS.md",
    "genui/AI_ANALYSIS.md"
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
