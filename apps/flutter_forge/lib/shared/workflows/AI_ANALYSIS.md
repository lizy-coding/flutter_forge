{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.shared.workflows",
    "kind": "shared_capability_index",
    "package": "flutter_forge_app",
    "path": "lib/shared/workflows",
    "status": "active"
  },
  "entrypoints": [
    "hub_client.dart"
  ],
  "owns": [
    "workflow_hub_http_transport",
    "ephemeral_connection_auth"
  ],
  "depends": [
    "dio"
  ],
  "children": [],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze",
    "flutter test test/modules/ui/workflow_workbench"
  ]
}
