{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "package_contract",
  "node": {
    "id": "flutter_forge.workspace.flutter_biometric",
    "kind": "flutter_plugin_package",
    "package": "flutter_biometric",
    "path": "packages/flutter_biometric",
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
    "lib/flutter_biometric.dart"
  ],
  "owns": [
    "biometric_capability_queries",
    "biometric_auth_outcomes",
    "biometric_native_lifecycle"
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
