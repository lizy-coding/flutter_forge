{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "package_contract",
  "node": {
    "id": "flutter_forge.workspace.forge_scene_viewer",
    "kind": "flutter_package",
    "package": "forge_scene_viewer",
    "path": "packages/forge_scene_viewer",
    "status": "active"
  },
  "package_type": "flutter_package",
  "workspace": {
    "member": true,
    "resolution": "workspace",
    "resolution_status": "active",
    "resolution_blocker": "none"
  },
  "entrypoints": [
    "lib/forge_scene_viewer.dart",
    "lib/build_hooks.dart"
  ],
  "owns": [
    "scene_runtime",
    "orbit_camera",
    "scene_selection",
    "render_scheduling",
    "render_diagnostics"
  ],
  "depends": [
    "flutter_sdk",
    "flutter_scene",
    "vector_math"
  ],
  "children": [],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze",
    "flutter test"
  ],
  "test_status": "configured"
}
