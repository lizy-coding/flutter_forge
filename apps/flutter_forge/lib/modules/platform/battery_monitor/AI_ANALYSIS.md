{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.platform.battery_monitor",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/platform/battery_monitor",
    "status": "ready"
  },
  "route": "/battery-monitor",
  "category": "platform",
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
      "web",
      "windows"
    ],
    "required_capabilities": [
      "battery_monitor"
    ],
    "unreviewed_dependencies": [],
    "optional_capabilities": [],
    "reasons": [
      {
        "capability": "battery_monitor",
        "reason": "battery_android_macos_native_adapters",
        "sources": [
          "packages/flutter_battery/pubspec.yaml",
          "apps/flutter_forge/lib/modules/platform/battery_monitor/module_entry.dart"
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
    "module_ui",
    "battery_session_lifecycle"
  ],
  "depends": [
    "shared_learning",
    "flutter_battery",
    "module_registry"
  ],
  "children": [],
  "analysis_parent": "lib/modules/platform/AI_ANALYSIS.md",
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze",
    "flutter test test/modules/platform/battery_monitor"
  ]
}
