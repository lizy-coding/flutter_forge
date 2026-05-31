{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.shared.platform",
    "kind": "platform_boundary_layer",
    "package": "main_app",
    "path": "lib/shared/platform",
    "status": "transition"
  },
  "entrypoints": ["AI_ANALYSIS.md"],
  "owns": ["platform_boundary_docs","host_channel_registry_docs"],
  "depends": ["../flutter_study_platform_file_picker","macos/Runner/AppDelegate.swift"],
  "mutates": ["AI_ANALYSIS.md","macos/Runner/AppDelegate.swift"],
  "files": [],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter build macos"]
}
