{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "package_contract",
  "node": {
    "id": "flutter_forge.workspace.bluetooth_system_bridge",
    "kind": "flutter_plugin_package",
    "package": "bluetooth_system_bridge",
    "path": "packages/bluetooth_system_bridge",
    "status": "active"
  },
  "package_type": "flutter_plugin_package",
  "workspace": {
    "member": true,
    "resolution": "workspace",
    "resolution_status": "active",
    "resolution_blocker": "none"
  },
  "entrypoints": [
    "lib/bluetooth_system_bridge.dart"
  ],
  "owns": [
    "bluetooth_system_settings",
    "bluetooth_audio_profile_queries",
    "bluetooth_system_operation_lifecycle"
  ],
  "depends": [
    "flutter_sdk",
    "plugin_platform_interface",
    "url_launcher"
  ],
  "children": [],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze",
    "flutter test"
  ],
  "test_status": "configured"
}
