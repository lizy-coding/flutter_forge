{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.platform.biometric_auth",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/platform/biometric_auth",
    "status": "ready"
  },
  "route": "/biometric-auth",
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
      "biometric_auth"
    ],
    "unreviewed_dependencies": [],
    "optional_capabilities": [],
    "reasons": [
      {
        "capability": "biometric_auth",
        "reason": "biometric_biometricprompt_localauth_adapters",
        "sources": [
          "apps/flutter_forge/pubspec.yaml",
          "apps/flutter_forge/lib/modules/platform/biometric_auth/module_entry.dart"
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
    "biometric_session_lifecycle"
  ],
  "depends": [
    "shared_learning",
    "flutter_biometric",
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
    "flutter test test/modules/platform/biometric_auth"
  ]
}
