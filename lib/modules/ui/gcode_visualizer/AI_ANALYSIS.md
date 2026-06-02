{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.ui.gcode_visualizer",
    "kind": "learning_module_adapter",
    "package": "main_app",
    "path": "lib/modules/ui/gcode_visualizer",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_routes.dart","module_root.dart","pages","widgets","state"],
  "owns": ["module_entry","module_ui","module_state","module_docs"],
  "depends": ["gcode_core","flutter_study_learning","file_picker_bridge","module_registry"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["gcode_readline.dart","module_entry.dart","pages/gcode_visualizer_page.dart","state/gcode_player_controller.dart","widgets/command_timeline.dart","widgets/gcode_canvas.dart","widgets/gcode_editor_panel.dart","widgets/playback_controls.dart"],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"]
}
