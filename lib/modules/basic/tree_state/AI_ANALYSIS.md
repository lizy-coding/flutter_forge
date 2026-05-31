{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.basic.tree_state",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/basic/tree_state",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_routes.dart","module_root.dart","pages","widgets","state"],
  "owns": ["module_entry","module_ui","module_state","module_docs"],
  "depends": ["flutter_study_learning","module_registry","go_router"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["module_entry.dart","module_routes.dart","pages/basic_widgets_page.dart","pages/demo_home_page.dart","pages/painter_demo_page.dart","pages/repaint_boundary_demo_page.dart","pages/state_lifecycle_page.dart","routes.dart"],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"]
}
