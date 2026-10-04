{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.async.isolate_task_manager",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/async/isolate_task_manager",
    "status": "ready"
  },
  "route": "/isolate-stream",
  "category": "async",
  "platform_support": {
    "target_platforms": [
      "android",
      "iOS",
      "macOS",
      "web",
      "windows"
    ],
    "excluded_platforms": [
      "web"
    ],
    "required_capabilities": [
      "isolates"
    ],
    "unreviewed_dependencies": [
      "collection"
    ],
    "optional_capabilities": [],
    "reasons": [
      {
        "capability": "isolates",
        "reason": "safari_isolate_progress_unreliable",
        "sources": [
          "apps/flutter_forge/lib/modules/async/isolate_basic",
          "apps/flutter_forge/lib/modules/async/isolate_task_manager"
        ]
      }
    ],
    "restriction": null,
    "features": {}
  },
  "entrypoints": [
    "module_entry.dart",
    "module_root.dart"
  ],
  "owns": [
    "module_entry",
    "module_ui",
    "module_docs"
  ],
  "depends": [
    "shared_learning",
    "module_registry"
  ],
  "children": [],
  "analysis_parent": "lib/modules/async/AI_ANALYSIS.md",
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
