{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.ui.popup_list_interaction",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/ui/popup_list_interaction",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_routes.dart","module_root.dart","pages"],
  "owns": ["module_entry","module_ui","module_docs"],
  "depends": ["popup_widgets","scroll_table","module_registry","go_router"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["module_entry.dart","module_root.dart","module_routes.dart","pages/popup_page.dart","pages/list_page.dart"],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"]
}
