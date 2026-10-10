{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "package_contract",
  "node": {
    "id": "flutter_forge.workspace.usb_network_bridge",
    "kind": "flutter_plugin_package",
    "package": "usb_network_bridge",
    "path": "packages/usb_network_bridge",
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
    "lib/usb_network_bridge.dart"
  ],
  "owns": [
    "ncm_interface_enumeration",
    "interface_bound_tcp",
    "native_relay_lifecycle"
  ],
  "depends": [
    "flutter_sdk",
    "ffi"
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
