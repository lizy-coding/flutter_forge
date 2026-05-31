{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.shared",
    "kind": "shared_layer",
    "package": "main_app",
    "path": "lib/shared",
    "status": "transition"
  },
  "entrypoints": ["AI_ANALYSIS.md"],
  "owns": ["boundary_docs","transition_layer"],
  "depends": ["../flutter_study_learning","../file_picker_bridge"],
  "mutates": ["AI_ANALYSIS.md","platform/AI_ANALYSIS.md"],
  "files": ["platform/AI_ANALYSIS.md"],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze"]
}
