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
    "git:https://github.com/lizy-coding/gcode_core.git#v0.2.1",
    "lib/shared/learning",
    "packages/forge_articles",
    "packages/forge_scene_viewer",
    "packages/usb_network_bridge",
    "packages/usb_detector_bridge",
    "packages/forge_notification_bridge",
    "packages/flutter_battery",
    "packages/file_picker_bridge",
    "packages/flutter_ioc_core",
    "packages/desktop_multi_window"
  ],
  "children": [
    "lib/AI_ANALYSIS.md",
    "lib/app/AI_ANALYSIS.md",
    "lib/module_registry/AI_ANALYSIS.md",
    "lib/shared/AI_ANALYSIS.md",
    "lib/modules/AI_ANALYSIS.md",
    "packages/forge_articles/AI_ANALYSIS.md",
    "packages/forge_scene_viewer/AI_ANALYSIS.md",
    "packages/usb_network_bridge/AI_ANALYSIS.md",
    "packages/usb_detector_bridge/AI_ANALYSIS.md",
    "packages/forge_notification_bridge/AI_ANALYSIS.md",
    "packages/flutter_battery/AI_ANALYSIS.md",
    "packages/file_picker_bridge/AI_ANALYSIS.md",
    "packages/flutter_ioc_core/AI_ANALYSIS.md",
    "packages/desktop_multi_window/AI_ANALYSIS.md"
  ],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "node --test tool/agent_indexes/generator.test.js",
    "node tool/generate_agent_indexes.js --check",
    "bash tool/generate_harness_ai_analysis.sh",
    "dart format --output=none --set-exit-if-changed .",
    "flutter analyze",
    "bash tool/quality_gate.sh"
  ]
}
