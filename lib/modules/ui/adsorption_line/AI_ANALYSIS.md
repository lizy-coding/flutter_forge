{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.ui.adsorption_line",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/ui/adsorption_line",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_routes.dart","module_root.dart","pages","widgets","state"],
  "owns": ["module_entry","module_ui","module_state","module_docs"],
  "depends": ["provider","module_registry"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["models/drawing_element.dart","module_entry.dart","services/adsorption_manager.dart","state/drawing_state.dart","widgets/drawing_board.dart","widgets/drawing_canvas.dart"],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"]
}
