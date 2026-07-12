{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_study.root",
    "kind": "workspace_index",
    "package": "main_app",
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
    "../gcode_core",
    "../flutter_study_learning",
    "../file_picker_bridge",
    "../flutter_ioc_core",
    "../flutterguard/packages/flutterguard_cli"
  ],
  "children": [
    "lib/AI_ANALYSIS.md",
    "lib/app/AI_ANALYSIS.md",
    "lib/module_registry/AI_ANALYSIS.md",
    "lib/shared/AI_ANALYSIS.md",
    "lib/modules/AI_ANALYSIS.md"
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
    "dart run flutterguard_cli:flutterguard scan --path . --fail-on high"
  ]
}
