{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.platform.network_diagnostics",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/platform/network_diagnostics",
    "status": "pending"
  },
  "route": "/network-diagnostics",
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
      "desktop_network_diagnostics"
    ],
    "unreviewed_dependencies": [],
    "optional_capabilities": [],
    "reasons": [
      {
        "capability": "desktop_network_diagnostics",
        "reason": "desktop_direct_network_probes_mobile_deferred_web_out_of_scope",
        "sources": [
          "apps/flutter_forge/lib/modules/platform/network_diagnostics/desktop_network_probe.dart",
          "docs/NETWORK_DIAGNOSTICS_DESIGN.md"
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
    "network_probe",
    "bounded_diagnostic_session",
    "session_report"
  ],
  "depends": [
    "shared_learning"
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
    "flutter test test/modules/platform/network_diagnostics"
  ]
}
