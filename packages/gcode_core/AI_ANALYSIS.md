{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "package_contract",
  "node": {
    "id": "flutter_study.workspace.gcode_core",
    "kind": "flutter_package",
    "package": "gcode_core",
    "path": "packages/gcode_core",
    "status": "active"
  },
  "package_type": "flutter_package",
  "workspace": {
    "member": true,
    "resolution": "workspace",
    "resolution_status": "blocked",
    "resolution_blocker": "test_analyzer_flutter_sdk_pin_conflict"
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
