{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.ui.download_animation",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/ui/download_animation",
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
    "models/animation_config.dart",
    "models/download_item.dart",
    "models/overlay_download_item.dart",
    "pages/download_animation_page.dart",
    "pages/download_comparison_page.dart",
    "pages/paint_animation_page.dart",
    "services/overlay_download_service.dart"
  ],
  "teaching_components": {
    "pages": [
      "module_root.dart",
      "pages/download_animation_page.dart",
      "pages/download_comparison_page.dart",
      "pages/paint_animation_page.dart"
    ],
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
