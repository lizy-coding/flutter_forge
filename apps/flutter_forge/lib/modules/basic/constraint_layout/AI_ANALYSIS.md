{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.basic.constraint_layout",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/basic/constraint_layout",
    "status": "ready"
  },
  "route": "/constraint-layout",
  "category": "basic",
  "platform_support": {
    "target_platforms": [
      "android",
      "iOS",
      "macOS",
      "web",
      "windows"
    ],
    "excluded_platforms": [],
    "required_capabilities": [],
    "unreviewed_dependencies": [],
    "optional_capabilities": [],
    "reasons": [],
    "restriction": null,
    "features": {}
  },
  "entrypoints": [
    "module_entry.dart",
    "pages"
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
  "analysis_parent": "lib/modules/basic/AI_ANALYSIS.md",
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze",
    "flutter test test/modules/basic/constraint_layout"
  ]
}
