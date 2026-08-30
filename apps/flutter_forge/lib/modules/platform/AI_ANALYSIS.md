{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.modules.platform",
    "kind": "module_category_index",
    "package": "flutter_forge_app",
    "path": "lib/modules/platform",
    "status": "active"
  },
  "entrypoints": [
    "dio_interceptor",
    "usb_detector",
    "file_picker",
    "online_video_player"
  ],
  "owns": [
    "network_platform"
  ],
  "depends": [
    "dio",
    "usb_serial",
    "device_info_plus",
    "video_player",
    "video_player_win",
    "flutter_study_learning",
    "file_picker_bridge"
  ],
  "children": [
    "dio_interceptor/AI_ANALYSIS.md",
    "usb_detector/AI_ANALYSIS.md",
    "file_picker/AI_ANALYSIS.md",
    "online_video_player/AI_ANALYSIS.md"
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
    "flutter analyze"
  ]
}
