{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.modules.ui",
    "kind": "module_category_index",
    "package": "flutter_forge_app",
    "path": "lib/modules/ui",
    "status": "active"
  },
  "entrypoints": [
    "gcode_visualizer",
    "adsorption_line",
    "download_animation",
    "font_picker"
  ],
  "owns": [
    "ui_animation_custom_paint"
  ],
  "depends": [
    "provider",
    "gcode_core",
    "file_picker_bridge",
    "flutter_study_learning",
    "module_registry"
  ],
  "children": [
    "gcode_visualizer/AI_ANALYSIS.md",
    "adsorption_line/AI_ANALYSIS.md",
    "download_animation/AI_ANALYSIS.md",
    "font_picker/AI_ANALYSIS.md"
  ],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
