{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.shared.popup",
    "kind": "shared_capability_index",
    "package": "flutter_forge_app",
    "path": "lib/shared/popup",
    "status": "active"
  },
  "entrypoints": [
    "popup_scope.dart"
  ],
  "owns": [
    "owned_popup_routes",
    "overlay_group_lifecycle",
    "cancellable_sequences"
  ],
  "depends": [
    "flutter_material"
  ],
  "children": [],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze",
    "flutter test test/shared/popup"
  ]
}
