{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "package_contract",
  "node": {
    "id": "flutter_forge.workspace.forge_articles",
    "kind": "dart_package",
    "package": "forge_articles",
    "path": "packages/forge_articles",
    "status": "active"
  },
  "package_type": "dart_package",
  "workspace": {
    "member": true,
    "resolution": "workspace",
    "resolution_status": "active",
    "resolution_blocker": "none"
  },
  "entrypoints": [
    "lib/forge_articles.dart"
  ],
  "owns": [
    "article_request_api",
    "synthetic_article_adapter",
    "article_workflow_execution"
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
    "dart analyze",
    "flutter test"
  ],
  "test_status": "configured"
}
