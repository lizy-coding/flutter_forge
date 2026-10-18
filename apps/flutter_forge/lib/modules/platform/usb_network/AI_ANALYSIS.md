{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.platform.usb_network",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/platform/usb_network",
    "status": "pending"
  },
  "route": "/usb-network",
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
      "web"
    ],
    "required_capabilities": [
      "usb_network"
    ],
    "unreviewed_dependencies": [],
    "optional_capabilities": [],
    "reasons": [
      {
        "capability": "usb_network",
        "reason": "desktop_system_ncm_interface_bound_tcp",
        "sources": [
          "packages/usb_network_bridge/pubspec.yaml",
          "packages/usb_network_bridge/lib/src/backend_native.dart"
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
    "module_docs",
    "tcp_session_lifecycle"
  ],
  "depends": [
    "shared_learning",
    "usb_network_bridge"
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
    "flutter test test/modules/platform/usb_network"
  ]
}
