{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "package_contract",
  "node": {
    "id": "flutter_study.workspace.flutter_study_learning",
    "kind": "flutter_package",
    "package": "flutter_study_learning",
    "path": "packages/flutter_study_learning",
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
    "lib/flutter_study_learning.dart"
  ],
  "owns": [
    "learning_scaffold_widgets",
    "teaching_ui_components"
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
