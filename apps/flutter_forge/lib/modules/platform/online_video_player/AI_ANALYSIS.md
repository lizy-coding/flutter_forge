{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "module_contract",
  "node": {
    "id": "flutter_forge_app.modules.platform.online_video_player",
    "kind": "learning_module",
    "package": "flutter_forge_app",
    "path": "lib/modules/platform/online_video_player",
    "status": "ready"
  },
  "route": "/online-video-player",
  "category": "platform",
  "supported_platforms": [
    "macOS",
    "windows"
  ],
  "entrypoints": [
    "module_entry.dart",
    "module_root.dart",
    "widgets",
    "state"
  ],
  "owns": [
    "module_entry",
    "module_ui",
    "module_docs"
  ],
  "depends": [
    "shared_learning",
    "dio",
    "video_player",
    "video_player_win",
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
    "flutter analyze"
  ]
}
