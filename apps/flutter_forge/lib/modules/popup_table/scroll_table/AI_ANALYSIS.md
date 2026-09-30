{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.popup_table.scroll_table",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/popup_table/scroll_table",
    "status": "ready"
  },
  "route": "/scroll-table",
  "category": "popup_table",
  "platform_support": {
    "target_platforms": [
      "android",
      "iOS",
      "macOS",
      "web",
      "windows"
    ],
    "excluded_platforms": []
  },
  "entrypoints": [
    "module_entry.dart",
    "module_root.dart",
    "widgets"
  ],
  "owns": [
    "module_entry",
    "module_ui",
    "module_docs",
    "table_sample_data"
  ],
  "depends": [
    "shared_learning",
    "shared_table",
    "module_registry"
  ],
  "children": [],
  "analysis_parent": "lib/modules/popup_table/AI_ANALYSIS.md",
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze",
    "flutter test test/modules/popup_table/scroll_table"
  ]
}
