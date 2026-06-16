{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.async.isolate_basic",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/async/isolate_basic",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_root.dart"],
  "owns": ["module_entry","module_ui"],
  "depends": ["flutter_study_learning","module_registry","go_router"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": [
    "module_entry.dart",
    "module_root.dart",
    "module_routes.dart",
    "with_isolate_page.dart",
    "without_isolate_page.dart"
  ],
  "teaching_components": {
    "page": "module_root.dart",
    "components": [
      "LearningScaffold",
      "LearningObjectives",
      "ConceptChips",
      "CodeSnippetCard",
      "CommonPitfalls",
      "ExerciseCard"
    ]
  },
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"]
}
