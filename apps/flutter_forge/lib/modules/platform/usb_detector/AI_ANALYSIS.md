{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.platform.usb_detector",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/platform/usb_detector",
    "status": "ready"
  },
  "route": "/usb-detector",
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
      "android",
      "iOS",
      "macOS",
      "web",
      "windows"
    ],
    "required_capabilities": [
      "usb_detection"
    ],
    "unreviewed_dependencies": [
      "device_info_plus"
    ],
    "optional_capabilities": [],
    "reasons": [
      {
        "capability": "usb_detection",
        "reason": "android_usb_manager_enumeration_only",
        "sources": [
          "packages/usb_detector_bridge/pubspec.yaml",
          "packages/usb_detector_bridge/lib/usb_detector_method_channel.dart"
        ]
      }
    ],
    "restriction": {
      "reason": "usb_otg_learning_workflow_deferred",
      "sources": [
        "tool/agent_indexes/plan.js"
      ]
    },
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
    "shared_learning",
    "usb_detector_bridge",
    "device_info_plus",
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
    "flutter analyze"
  ]
}
