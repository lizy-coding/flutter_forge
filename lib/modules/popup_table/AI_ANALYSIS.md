{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "main_app.modules.popup_table",
    "kind": "module_category_index",
    "package": "main_app",
    "path": "lib/modules/popup_table",
    "status": "active"
  },
  "entrypoints": [
    "popup_widgets",
    "popup_list_interaction",
    "scroll_table",
    "overlay_follow_compare"
  ],
  "owns": [
    "popup_overlay_table"
  ],
  "depends": [
    "module_registry",
    "flutter_study_learning",
    "two_dimensional_scrollables"
  ],
  "children": [
    "popup_widgets/AI_ANALYSIS.md",
    "popup_list_interaction/AI_ANALYSIS.md",
    "scroll_table/AI_ANALYSIS.md",
    "overlay_follow_compare/AI_ANALYSIS.md"
  ],
  "contracts": {
    "no_natural_language": true,
    "index_only": true,
    "max_index_depth": 2,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": [
    "flutter analyze"
  ]
}
