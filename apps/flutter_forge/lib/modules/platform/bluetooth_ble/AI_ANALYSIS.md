{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.platform.bluetooth_ble",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/platform/bluetooth_ble",
    "status": "ready"
  },
  "route": "/bluetooth-ble",
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
      "web"
    ],
    "required_capabilities": [
      "ble_central"
    ],
    "unreviewed_dependencies": [
      "url_launcher"
    ],
    "optional_capabilities": [],
    "reasons": [
      {
        "capability": "ble_central",
        "reason": "ble_central_adapters",
        "sources": [
          "apps/flutter_forge/lib/modules/platform/bluetooth_ble/module_entry.dart",
          "apps/flutter_forge/lib/modules/platform/bluetooth_ble/state/ble_session.dart"
        ]
      }
    ],
    "restriction": null,
    "features": {}
  },
  "entrypoints": [
    "module_entry.dart",
    "module_root.dart",
    "state"
  ],
  "owns": [
    "module_entry",
    "module_ui",
    "module_docs",
    "scan_lifecycle",
    "gatt_lifecycle",
    "advertisement_history"
  ],
  "depends": [
    "shared_learning",
    "universal_ble",
    "url_launcher",
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
    "flutter test test/modules/platform/bluetooth_ble"
  ]
}
