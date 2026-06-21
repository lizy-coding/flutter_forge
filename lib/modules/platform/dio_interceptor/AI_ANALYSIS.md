{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "main_app.modules.platform.dio_interceptor",
    "kind": "learning_module",
    "package": "main_app",
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
    "flutter_study_learning",
    "dio",
    "module_registry",
    "go_router"
  ],
  "children": [],
  "analysis_parent": "lib/modules/platform/AI_ANALYSIS.md",
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
