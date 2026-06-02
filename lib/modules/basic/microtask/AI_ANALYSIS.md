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
  "entrypoints": ["module_entry.dart","module_routes.dart","module_root.dart","pages","widgets","state"],
  "owns": ["module_entry","module_ui","module_state","module_docs"],
  "depends": ["module_registry","go_router"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["core/models/event_log.dart","core/widgets/code_snippet_view.dart","core/widgets/event_log_view.dart","features/advanced_examples/advanced_examples_page.dart","features/event_queue/event_queue_page.dart","features/home_page.dart","features/microtask_queue/microtask_queue_page.dart","module_entry.dart","module_routes.dart"],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"]
}
