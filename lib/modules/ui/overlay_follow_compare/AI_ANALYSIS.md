{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.ui.overlay_follow_compare",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/ui/overlay_follow_compare",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_root.dart","widgets"],
  "owns": ["module_entry","module_ui","module_docs"],
  "depends": ["module_registry"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": [
    "module_entry.dart",
    "module_root.dart",
    "widgets/compare_panel.dart",
    "widgets/follower_demo.dart",
    "widgets/manual_demo.dart",
    "widgets/dropdown_surface.dart",
    "widgets/status_info.dart"
  ],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"]
}
