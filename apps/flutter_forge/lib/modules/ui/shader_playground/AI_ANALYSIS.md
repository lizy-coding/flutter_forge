{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.ui.shader_playground",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/ui/shader_playground",
    "status": "ready"
  },
  "route": "/shader-playground",
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
      "fragment_shader_canvas"
    ],
    "unreviewed_dependencies": [],
    "optional_capabilities": [],
    "reasons": [
      {
        "capability": "fragment_shader_canvas",
        "reason": "sdk_fragment_program_canvas_skia_impeller",
        "sources": [
          "apps/flutter_forge/lib/modules/ui/shader_playground/shader_preview.dart",
          "apps/flutter_forge/pubspec.yaml"
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
    "shared_learning"
  ],
  "children": [],
  "analysis_parent": "lib/modules/ui/AI_ANALYSIS.md",
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
