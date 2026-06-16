{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.state.status_management",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/state/status_management",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart"],
  "owns": ["module_entry","module_ui"],
  "depends": ["flutter_study_learning","module_registry","go_router","provider","flutter_riverpod","flutter_bloc"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": [
    "module_entry.dart",
    "module_routes.dart",
    "pages/home_page.dart",
    "pages/provider/provider_route.dart",
    "pages/provider/provider_lifting_route.dart",
    "pages/provider/provider_future_route.dart",
    "pages/provider/provider_todo_route.dart",
    "pages/provider/models/counter_cn.dart",
    "pages/provider/widgets/granular_grid.dart",
    "pages/provider/widgets/provider_perks.dart",
    "pages/riverpod/riverpod_route.dart",
    "pages/riverpod/riverpod_lifting_route.dart",
    "pages/riverpod/riverpod_future_route.dart",
    "pages/riverpod/riverpod_todo_route.dart",
    "pages/bloc/bloc_route.dart",
    "pages/bloc/counter_bloc.dart",
    "pages/bloc/counter_event.dart",
    "pages/bloc/counter_state.dart",
    "widgets/state_flow_demo.dart"
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
