{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.shared.table",
    "kind": "shared_capability_index",
    "package": "flutter_forge_app",
    "path": "lib/shared/table",
    "status": "active"
  },
  "entrypoints": [
    "scroll_table.dart"
  ],
  "owns": [
    "two_dimensional_table_view",
    "pinned_headers",
    "cell_interaction_callbacks"
  ],
  "depends": [
    "flutter_material",
    "two_dimensional_scrollables"
  ],
  "children": [],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze",
    "flutter test test/modules/popup_table"
  ]
}
