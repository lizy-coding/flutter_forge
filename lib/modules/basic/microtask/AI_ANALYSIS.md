{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.basic.microtask",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/basic/microtask",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart"],
  "owns": ["module_entry","module_ui"],
  "depends": ["flutter_study_learning","module_registry","go_router"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": [
    "module_entry.dart",
    "module_routes.dart",
    "models/event_log.dart",
    "widgets/code_snippet_view.dart",
    "widgets/event_log_view.dart",
    "pages/home_page.dart",
    "pages/event_queue_page.dart",
    "pages/microtask_queue_page.dart",
    "pages/advanced_examples_page.dart"
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
