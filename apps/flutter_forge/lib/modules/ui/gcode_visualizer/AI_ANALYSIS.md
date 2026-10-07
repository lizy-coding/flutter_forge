{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.ui.gcode_visualizer",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/ui/gcode_visualizer",
    "status": "ready"
  },
  "route": "/gcode-visualizer",
  "category": "ui",
  "platform_support": {
    "target_platforms": [
      "android",
      "iOS",
      "macOS",
      "web",
      "windows"
    ],
    "excluded_platforms": [
      "android",
      "iOS",
      "web",
      "windows"
    ],
    "required_capabilities": [
      "gcode_render",
      "file_selection"
    ],
    "unreviewed_dependencies": [],
    "optional_capabilities": [],
    "reasons": [
      {
        "capability": "gcode_render",
        "reason": "macos_gcode_adapter_only",
        "sources": [
          "apps/flutter_forge/lib/modules/ui/gcode_visualizer/module_entry.dart",
          "apps/flutter_forge/pubspec.yaml"
        ]
      },
      {
        "capability": "file_selection",
        "reason": "file_bridge_adapters_web_filename_only",
        "sources": [
          "packages/file_picker_bridge/lib/file_picker_bridge.dart"
        ]
      }
    ],
    "restriction": null,
    "features": {}
  },
  "entrypoints": [
    "module_entry.dart",
    "pages",
    "widgets",
    "state"
  ],
  "owns": [
    "module_entry",
    "module_ui",
    "module_docs"
  ],
  "depends": [
    "shared_learning",
    "gcode_core",
    "file_picker_bridge",
    "module_registry"
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
