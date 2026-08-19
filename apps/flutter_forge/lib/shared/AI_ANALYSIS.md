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
    "multi_window",
    "platform"
  ],
  "owns": [
    "business_free_capabilities",
    "desktop_window_lifecycle",
    "platform_boundaries"
  ],
  "depends": [
    "desktop_multi_window",
    "packages/file_picker_bridge"
  ],
  "children": [
    "multi_window/AI_ANALYSIS.md",
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
