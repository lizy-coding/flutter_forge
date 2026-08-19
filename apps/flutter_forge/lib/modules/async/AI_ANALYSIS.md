{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.modules.async",
    "kind": "module_category_index",
    "package": "flutter_forge_app",
    "path": "lib/modules/async",
    "status": "active"
  },
  "entrypoints": [
    "stream_subscription",
    "isolate_basic",
    "isolate_task_manager"
  ],
  "owns": [
    "async_concurrency"
  ],
  "depends": [
    "module_registry",
    "flutter_study_learning"
  ],
  "children": [
    "stream_subscription/AI_ANALYSIS.md",
    "isolate_basic/AI_ANALYSIS.md",
    "isolate_task_manager/AI_ANALYSIS.md"
  ],
  "contracts": {
    "no_natural_language": true,
    "index_only": true,
    "max_index_depth": 2,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": [
    "flutter analyze"
  ]
}
