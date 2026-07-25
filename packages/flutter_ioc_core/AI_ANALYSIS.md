{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "package_contract",
  "node": {
    "id": "flutter_study.workspace.flutter_ioc_core",
    "kind": "dart_package",
    "package": "flutter_ioc_core",
    "path": "packages/flutter_ioc_core",
    "status": "active"
  },
  "package_type": "dart_package",
  "workspace": {
    "member": true,
    "resolution": "workspace",
    "resolution_status": "blocked",
    "resolution_blocker": "test_analyzer_flutter_sdk_pin_conflict"
  },
  "entrypoints": [
    "lib/flutter_ioc_core.dart"
  ],
  "owns": [
    "ioc_container",
    "registration_lifetimes",
    "scoped_resolution"
  ],
  "depends": [],
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
    "dart pub get",
    "dart analyze"
  ],
  "test_status": "missing_test_directory"
}
