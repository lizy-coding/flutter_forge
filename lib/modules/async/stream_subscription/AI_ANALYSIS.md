{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.async.stream_subscription",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/async/stream_subscription",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_routes.dart","module_root.dart","pages","widgets","state"],
  "owns": ["module_entry","module_ui","module_state","module_docs"],
  "depends": ["module_registry","go_router"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["models/message_model.dart","module_entry.dart","module_routes.dart","pages/broadcast_demo/broadcast_demo_page.dart","pages/home_page.dart","pages/stream_demo_controller.dart","pages/stream_demo_page.dart","services/stream_service.dart","utils/stream_utils.dart"],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"]
}
