{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.ui.flutter_scene_3d",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/ui/flutter_scene_3d",
    "status": "pending"
  },
  "route": "/flutter-scene-3d",
  "category": "ui",
  "supported_platforms": [
    "macOS"
  ],
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
    "flutter_scene",
    "vector_math",
    "module_registry"
  ],
  "children": [],
  "analysis_parent": "lib/modules/ui/AI_ANALYSIS.md",
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
