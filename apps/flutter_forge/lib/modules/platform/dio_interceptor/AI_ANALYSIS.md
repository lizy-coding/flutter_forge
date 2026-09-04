{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.platform.dio_interceptor",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/platform/dio_interceptor",
    "status": "ready"
  },
  "route": "/dio-interceptor",
  "category": "platform",
  "entrypoints": [
    "module_entry.dart",
    "module_routes.dart",
    "pages"
  ],
  "owns": [
    "module_entry",
    "module_ui",
    "module_docs"
  ],
  "depends": [
    "shared_learning",
    "dio",
    "module_registry",
    "go_router"
  ],
  "children": [],
  "analysis_parent": "lib/modules/platform/AI_ANALYSIS.md",
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
