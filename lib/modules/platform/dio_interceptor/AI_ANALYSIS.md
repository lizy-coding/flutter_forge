{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.platform.dio_interceptor",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/platform/dio_interceptor",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart"],
  "owns": ["module_entry","module_ui"],
  "depends": ["flutter_study_learning","module_registry","go_router","dio"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": [
    "module_entry.dart",
    "module_routes.dart",
    "mock_server/mock_server.dart",
    "models/article.dart",
    "network/http_client.dart",
    "network/api/api_service.dart",
    "network/interceptor/auth_interceptor.dart",
    "network/interceptor/error_interceptor.dart",
    "network/interceptor/log_interceptor.dart",
    "network/interceptor/retry_interceptor.dart",
    "pages/home_page.dart",
    "pages/login_page.dart"
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
