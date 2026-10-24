{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.ui.workflow_workbench",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/ui/workflow_workbench",
    "status": "ready"
  },
  "route": "/workflow-workbench",
  "category": "ui",
  "platform_support": {
    "target_platforms": [
      "android",
      "iOS",
      "macOS",
      "web",
      "windows"
    ],
    "excluded_platforms": [],
    "required_capabilities": [
      "article_workflow",
      "genui_surface"
    ],
    "unreviewed_dependencies": [],
    "optional_capabilities": [],
    "reasons": [
      {
        "capability": "article_workflow",
        "reason": "pure_dart_article_request_and_teaching_adapter",
        "sources": [
          "packages/forge_articles/pubspec.yaml",
          "packages/forge_articles/lib/forge_articles.dart"
        ]
      },
      {
        "capability": "genui_surface",
        "reason": "bounded_flutter_catalog_and_http_stream_no_native_model_runtime",
        "sources": [
          "apps/flutter_forge/lib/modules/ui/genui_workbench/workbench_catalog.dart",
          "apps/flutter_forge/lib/modules/ui/genui_workbench/workbench_source.dart",
          "apps/flutter_forge/pubspec.yaml"
        ]
      }
    ],
    "restriction": null,
    "features": {}
  },
  "entrypoints": [
    "module_entry.dart"
  ],
  "owns": [
    "module_entry",
    "workflow_executor_session",
    "schema_driven_inputs",
    "hub_result_surface"
  ],
  "depends": [
    "shared_learning",
    "shared_table",
    "shared_workflows",
    "forge_articles",
    "genui",
    "a2ui_core",
    "json_schema_builder",
    "dio"
  ],
  "children": [],
  "analysis_parent": "lib/modules/ui/AI_ANALYSIS.md",
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
