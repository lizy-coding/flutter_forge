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
  "entrypoints": ["module_entry.dart","module_routes.dart","module_root.dart","pages","widgets","state"],
  "owns": ["module_entry","module_ui","module_state","module_docs"],
  "depends": ["dio","module_registry","go_router"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["mock_server/mock_server.dart","models/article.dart","module_entry.dart","module_routes.dart","network/api/api_service.dart","network/http_client.dart","network/interceptor/auth_interceptor.dart","network/interceptor/error_interceptor.dart","network/interceptor/log_interceptor.dart","network/interceptor/retry_interceptor.dart","pages/home_page.dart","pages/login_page.dart"],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"]
}
