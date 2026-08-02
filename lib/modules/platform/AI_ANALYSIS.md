{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "main_app.modules.platform",
    "kind": "module_category_index",
    "package": "main_app",
    "path": "lib/modules/platform",
    "status": "active"
  },
  "entrypoints": [
    "dio_interceptor",
    "usb_detector",
    "online_video_player"
  ],
  "owns": [
    "network_platform"
  ],
  "depends": [
    "dio",
    "usb_serial",
    "device_info_plus",
    "media_kit",
    "media_kit_video",
    "flutter_study_learning"
  ],
  "children": [
    "dio_interceptor/AI_ANALYSIS.md",
    "usb_detector/AI_ANALYSIS.md",
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
