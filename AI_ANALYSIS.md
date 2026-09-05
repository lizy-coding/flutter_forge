{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge.root",
    "kind": "workspace_index",
    "package": "flutter_forge_app",
    "path": ".",
    "status": "active"
  },
  "entrypoints": [
    "lib/main.dart",
    "lib/app/app_bootstrap.dart",
    "lib/app/app.dart",
    "lib/app/router/app_route_table.dart"
  ],
  "owns": [
    "app_shell",
    "module_registry",
    "shared_capabilities",
    "learning_modules",
    "host_integrations"
  ],
  "depends": [
    "git:https://github.com/lizy-coding/gcode_core.git#7a5228126d6e43b0cb9175b035cd2e1701950779",
    "packages/shared_learning",
    "packages/file_picker_bridge",
    "packages/flutter_ioc_core",
    "git:https://github.com/lizy-coding/flutterguard.git#9f9be84a73dc4b99a956a8529b8c334849566b03"
  ],
  "children": [
    "lib/AI_ANALYSIS.md",
    "lib/app/AI_ANALYSIS.md",
    "lib/module_registry/AI_ANALYSIS.md",
    "lib/shared/AI_ANALYSIS.md",
    "lib/modules/AI_ANALYSIS.md",
    "packages/file_picker_bridge/AI_ANALYSIS.md",
    "packages/flutter_ioc_core/AI_ANALYSIS.md"
  ],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "bash tool/generate_harness_ai_analysis.sh",
    "dart format .",
    "flutter analyze",
    "dart run flutterguard_cli:flutterguard scan . --fail-on high"
  ]
}
