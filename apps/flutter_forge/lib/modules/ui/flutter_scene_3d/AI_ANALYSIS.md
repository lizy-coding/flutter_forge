{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.ui.flutter_scene_3d",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/ui/flutter_scene_3d",
    "status": "ready"
  },
  "route": "/flutter-scene-3d",
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
      "iOS",
      "web"
    ],
    "required_capabilities": [
      "scene_render"
    ],
    "unreviewed_dependencies": [],
    "optional_capabilities": [],
    "reasons": [
      {
        "capability": "scene_render",
        "reason": "scene_gpu_adapters",
        "sources": [
          "apps/flutter_forge/android/app/src/main/AndroidManifest.xml",
          "apps/flutter_forge/windows/runner/main.cpp",
          "apps/flutter_forge/lib/modules/ui/flutter_scene_3d/module_entry.dart"
        ]
      }
    ],
    "restriction": null,
    "features": {
      "scene_controls": {
        "platforms": [
          "macOS",
          "windows"
        ],
        "reason": "desktop_scene_controls_android_view_only",
        "sources": [
          "apps/flutter_forge/test/modules/ui/flutter_scene_3d/flutter_scene_3d_test.dart"
        ]
      }
    }
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
    "flutter_scene",
    "vector_math",
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
