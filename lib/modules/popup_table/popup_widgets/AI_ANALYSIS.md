{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.popup_table.popup_widgets",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/popup_table/popup_widgets",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_root.dart"],
  "owns": ["module_entry","module_ui"],
  "depends": ["module_registry","flutter_study_learning"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["module_entry.dart","module_root.dart"],
  "classes": {
    "PopDemoHomePage": ["stateful_page_entry"],
    "_PopDemoHomePageState": [
      "learning_scaffold_builder",
      "demo_trigger_methods_9",
      "chain_dialog_state",
      "overlay_dialog_state"
    ],
    "ChainOrderStore": ["value_notifier_model", "chain_dialog_order"],
    "_CupertinoDoubleTapTile": ["gesture_detector", "cupertino_dialog_trigger"],
    "_ContextMenuTile": ["gesture_detector", "context_menu_trigger"]
  },
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"],
  "refactoring": {
    "date": "2026-06-15",
    "id": "retrofit_p0_learning_scaffold",
    "changes": [
      "replace_scaffold_with_learning_scaffold",
      "remove_popscope_exit_confirmation",
      "remove_drawer",
      "move_about_dialog_to_demo_list",
      "move_appbar_actions_to_toolbar_row",
      "replace_persistent_bottom_sheet_controller",
      "add_teaching_sections_5",
      "add_widget_smoke_test"
    ]
  }
}
