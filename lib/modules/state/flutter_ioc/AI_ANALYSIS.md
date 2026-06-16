{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.state.flutter_ioc",
    "kind": "learning_module_adapter",
    "package": "main_app",
    "path": "lib/modules/state/flutter_ioc",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_routes.dart","module_root.dart","pages","widgets","state"],
  "owns": ["module_entry","module_ui","module_state","module_docs"],
  "depends": ["flutter_ioc_core","provider","module_registry"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["model/counter_model.dart","module_entry.dart","module_root.dart"],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
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
  "validation": ["flutter analyze","flutter test"]
}
