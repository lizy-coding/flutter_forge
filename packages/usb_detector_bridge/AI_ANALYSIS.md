{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "package_contract",
  "node": {
    "id": "flutter_forge.workspace.usb_detector_bridge",
    "kind": "flutter_plugin_package",
    "package": "usb_detector_bridge",
    "path": "packages/usb_detector_bridge",
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
    "lib/usb_detector_bridge.dart"
  ],
  "owns": [
    "usb_device_enumeration",
    "usb_permission_gated_descriptors",
    "usb_detection_capabilities",
    "usb_detection_outcomes"
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
