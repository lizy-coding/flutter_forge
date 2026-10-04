{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.ui.font_picker",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/ui/font_picker",
    "status": "ready"
  },
  "route": "/font-picker",
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
    "required_capabilities": [],
    "unreviewed_dependencies": [],
    "optional_capabilities": [
      "font_file_import"
    ],
    "reasons": [
      {
        "capability": "font_file_import",
        "reason": "font_import_requires_native_bytes_and_file_bridge",
        "sources": [
          "apps/flutter_forge/lib/modules/ui/font_picker/pages/font_picker_page.dart",
          "apps/flutter_forge/lib/modules/ui/font_picker/pages/font_picker_web_page.dart"
        ]
      }
    ],
    "restriction": null,
    "features": {
      "font_file_import": {
        "platforms": [
          "android",
          "macOS",
          "windows"
        ],
        "reason": "font_import_requires_native_bytes_and_file_bridge",
        "sources": [
          "apps/flutter_forge/lib/modules/ui/font_picker/pages/font_picker_page.dart",
          "apps/flutter_forge/lib/modules/ui/font_picker/pages/font_picker_web_page.dart"
        ]
      },
      "font_preview": {
        "platforms": [
          "android",
          "iOS",
          "macOS",
          "windows"
        ],
        "reason": "web_font_page_has_no_native_preview_controls",
        "sources": [
          "apps/flutter_forge/lib/modules/ui/font_picker/pages/font_picker_web_page.dart"
        ]
      }
    }
  },
  "entrypoints": [
    "module_entry.dart",
    "module_root.dart",
    "module_routes.dart",
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
    "file_picker_bridge",
    "module_registry",
    "go_router"
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
