{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.ui.genui_workbench",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/ui/genui_workbench",
    "status": "ready"
  },
  "route": "/genui-workbench",
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
      "genui_surface"
    ],
    "unreviewed_dependencies": [],
    "optional_capabilities": [],
    "reasons": [
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
    "generated_experiment_surface",
    "bounded_catalog",
    "session_lifecycle",
    "layout_observation"
  ],
  "depends": [
    "shared_learning",
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
    "flutter test test/modules/ui/genui_workbench"
  ]
}
