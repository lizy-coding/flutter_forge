{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "package_contract",
  "node": {
    "id": "flutter_forge.workspace.gcode_core",
    "kind": "flutter_package",
    "package": "gcode_core",
    "path": "packages/gcode_core",
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
    "lib/gcode_core.dart"
  ],
  "owns": [
    "gcode_parsing",
    "line_reading",
    "toolpath_building",
    "flutter_visualization_widgets"
  ],
  "depends": [
    "flutter_sdk"
  ],
  "children": [],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter pub get",
    "flutter analyze",
    "flutter test"
  ],
  "test_status": "configured"
}
