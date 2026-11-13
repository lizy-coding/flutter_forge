{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "package_contract",
  "node": {
    "id": "flutter_forge.workspace.forge_notification_bridge",
    "kind": "flutter_plugin_package",
    "package": "forge_notification_bridge",
    "path": "packages/forge_notification_bridge",
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
    "lib/forge_notification_bridge.dart"
  ],
  "owns": [
    "notification_capability_queries",
    "notification_permission_states",
    "notification_post_outcomes",
    "notification_channel_contract"
  ],
  "depends": [
    "flutter_sdk",
    "plugin_platform_interface"
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
