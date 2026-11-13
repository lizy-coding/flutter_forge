{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "package_contract",
  "node": {
    "id": "flutter_forge.workspace.forge_app_info",
    "kind": "flutter_package",
    "package": "forge_app_info",
    "path": "packages/forge_app_info",
    "status": "active"
  },
  "package_type": "flutter_package",
  "workspace": {
    "member": true,
    "resolution": "workspace",
    "resolution_status": "active",
    "resolution_blocker": "none"
  },
  "entrypoints": [
    "lib/forge_app_info.dart"
  ],
  "owns": [
    "installed_app_version",
    "app_info_outcomes"
  ],
  "depends": [
    "flutter_sdk",
    "package_info_plus",
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
