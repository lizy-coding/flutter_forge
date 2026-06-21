{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "main_app.modules.state.flutter_ioc",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/state/flutter_ioc",
    "status": "ready"
  },
  "route": "/flutter-ioc",
  "category": "state",
  "entrypoints": [
    "module_entry.dart",
    "module_root.dart"
  ],
  "owns": [
    "module_entry",
    "module_ui",
    "module_docs"
  ],
  "depends": [
    "flutter_study_learning",
    "flutter_ioc_core",
    "provider",
    "module_registry"
  ],
  "children": [],
  "analysis_parent": "lib/modules/state/AI_ANALYSIS.md",
  "contracts": {
    "no_natural_language": true,
    "index_only": true,
    "max_index_depth": 2,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": [
    "flutter analyze"
  ]
}
