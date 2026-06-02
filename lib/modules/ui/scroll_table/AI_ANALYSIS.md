{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.ui.scroll_table",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/ui/scroll_table",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_routes.dart","module_root.dart","pages","widgets","state"],
  "owns": ["module_entry","module_ui","module_state","module_docs"],
  "depends": ["two_dimensional_scrollables","module_registry"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["module_entry.dart","module_root.dart","widgets/scroll_table.dart"],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"]
}
