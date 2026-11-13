{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.platform.system_notification",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/platform/system_notification",
    "status": "ready"
  },
  "route": "/system-notification",
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
      "notification_posting"
    ],
    "unreviewed_dependencies": [],
    "optional_capabilities": [],
    "reasons": [
      {
        "capability": "notification_posting",
        "reason": "notification_android_macos_local_adapters",
        "sources": [
          "packages/forge_notification_bridge/pubspec.yaml",
          "packages/forge_notification_bridge/lib/forge_notification_method_channel.dart"
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
    "notification_session_lifecycle"
  ],
  "depends": [
    "shared_learning",
    "forge_notification_bridge",
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
    "flutter test test/modules/platform/system_notification"
  ]
}
