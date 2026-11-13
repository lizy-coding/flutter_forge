{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.shared.platform",
    "kind": "shared_boundary_index",
    "package": "flutter_forge_app",
    "path": "lib/shared/platform",
    "status": "transition"
  },
  "entrypoints": [
    "build_features.dart"
  ],
  "owns": [
    "platform_boundary",
    "host_channel_registry",
    "compile_time_offline_distribution_policy"
  ],
  "depends": [
    "packages/file_picker_bridge",
    "macos/Runner/AppDelegate.swift"
  ],
  "children": [],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze",
    "flutter build macos"
  ]
}
