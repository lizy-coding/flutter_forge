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
    "bluetooth_ble",
    "file_picker",
    "online_video_player",
    "webview"
  ],
  "owns": [
    "network_platform"
  ],
  "depends": [
    "dio",
    "device_info_plus",
    "universal_ble",
    "video_player",
    "video_player_web",
    "video_player_win",
    "shared_learning",
    "file_picker_bridge",
    "webview_flutter",
    "webview_windows"
  ],
  "children": [
    "dio_interceptor/AI_ANALYSIS.md",
    "usb_detector/AI_ANALYSIS.md",
    "bluetooth_ble/AI_ANALYSIS.md",
    "file_picker/AI_ANALYSIS.md",
    "online_video_player/AI_ANALYSIS.md",
    "webview/AI_ANALYSIS.md"
  ],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
