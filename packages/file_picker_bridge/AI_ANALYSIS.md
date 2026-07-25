{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "package_contract",
  "node": {
    "id": "flutter_study.workspace.file_picker_bridge",
    "kind": "flutter_bridge_package",
    "package": "file_picker_bridge",
    "path": "packages/file_picker_bridge",
    "status": "active"
  },
  "package_type": "flutter_bridge_package",
  "workspace": {
    "member": true,
    "resolution": "workspace",
    "resolution_status": "blocked",
    "resolution_blocker": "test_analyzer_flutter_sdk_pin_conflict"
  },
  "entrypoints": [
    "lib/file_picker_bridge.dart"
  ],
  "owns": [
    "file_picker_api",
    "method_channel_client"
  ],
  "depends": [
    "flutter_sdk"
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
    "flutter pub get",
    "flutter analyze",
    "flutter test"
  ],
  "test_status": "configured"
}
