{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.shared.multi_window",
    "kind": "shared_capability_index",
    "package": "flutter_forge_app",
    "path": "lib/shared/multi_window",
    "status": "active"
  },
  "entrypoints": [
    "multi_window_manager.dart",
    "mac_window.dart"
  ],
  "owns": [
    "desktop_window_lifecycle",
    "desktop_window_arguments",
    "window_backend_protocol"
  ],
  "depends": [
    "desktop_multi_window",
    "module_registry"
  ],
  "children": [],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
