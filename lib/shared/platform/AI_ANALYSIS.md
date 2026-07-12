{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "main_app.shared.platform",
    "kind": "shared_boundary_index",
    "package": "main_app",
    "path": "lib/shared/platform",
    "status": "transition"
  },
  "entrypoints": [
    "AI_ANALYSIS.md"
  ],
  "owns": [
    "platform_boundary",
    "host_channel_registry"
  ],
  "depends": [
    "../file_picker_bridge",
    "macos/Runner/AppDelegate.swift"
  ],
  "children": [],
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
    "flutter analyze",
    "flutter build macos"
  ]
}
