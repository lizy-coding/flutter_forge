{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.state.flutter_ioc",
    "kind": "learning_module",
    "package": "flutter_forge_app",
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
    "shared_learning",
    "flutter_ioc_core",
    "provider",
    "module_registry"
  ],
  "children": [],
  "analysis_parent": "lib/modules/state/AI_ANALYSIS.md",
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
