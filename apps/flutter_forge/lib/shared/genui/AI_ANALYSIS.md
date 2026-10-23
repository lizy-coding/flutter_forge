{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.shared.genui",
    "kind": "shared_capability_index",
    "package": "flutter_forge_app",
    "path": "lib/shared/genui",
    "status": "active"
  },
  "entrypoints": [
    "model_source.dart",
    "model_connection_dialog.dart"
  ],
  "owns": [
    "bounded_model_transport",
    "ephemeral_model_connection_form"
  ],
  "depends": [
    "dio",
    "flutter_material"
  ],
  "children": [],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
