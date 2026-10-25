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
    "model_connection_dialog.dart",
    "session_core.dart"
  ],
  "owns": [
    "bounded_model_transport",
    "model_connection_form_with_remembered_endpoint",
    "ephemeral_access_token",
    "a2ui_session_run_state_machine"
  ],
  "depends": [
    "dio",
    "flutter_material",
    "genui",
    "a2ui_core",
    "shared_preferences"
  ],
  "children": [],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze",
    "flutter test test/shared/genui_session_core_test.dart test/shared/model_connection_dialog_test.dart"
  ]
}
