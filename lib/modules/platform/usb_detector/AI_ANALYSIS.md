{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.platform.usb_detector",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/platform/usb_detector",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_root.dart"],
  "owns": ["module_entry","module_ui"],
  "depends": ["flutter_study_learning","module_registry"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["module_entry.dart","module_root.dart","models/usb_device_info.dart","services/usb_detection_service.dart"],
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
