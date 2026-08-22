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
    "packages/gcode_core",
    "packages/flutter_study_learning",
    "packages/file_picker_bridge",
    "packages/flutter_ioc_core",
    "path:../../../flutterguard"
  ],
  "children": [
    "lib/AI_ANALYSIS.md",
    "lib/app/AI_ANALYSIS.md",
    "lib/module_registry/AI_ANALYSIS.md",
    "lib/shared/AI_ANALYSIS.md",
    "lib/modules/AI_ANALYSIS.md",
    "packages/gcode_core/AI_ANALYSIS.md",
    "packages/flutter_study_learning/AI_ANALYSIS.md",
    "packages/file_picker_bridge/AI_ANALYSIS.md",
    "packages/flutter_ioc_core/AI_ANALYSIS.md"
  ],
  "contracts": {
    "no_natural_language": true,
    "index_only": true,
    "max_index_depth": 2,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": [
    "bash tool/generate_harness_ai_analysis.sh",
    "dart format .",
    "flutter analyze",
    "dart run flutterguard_cli:flutterguard scan . --fail-on high"
  ]
}
