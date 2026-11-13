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
    "usb_network",
    "network_diagnostics",
    "usb_detector",
    "battery_monitor",
    "bluetooth_ble",
    "file_picker",
    "online_video_player",
    "biometric_auth",
    "system_notification",
    "webview"
  ],
  "owns": [
    "network_platform"
  ],
  "depends": [
    "shared_learning",
    "dio",
    "forge_articles",
    "module_registry",
    "go_router",
    "usb_network_bridge",
    "usb_detector_bridge",
    "device_info_plus",
    "flutter_battery",
    "universal_ble",
    "bluetooth_system_bridge",
    "file_picker_bridge",
    "video_player",
    "video_player_web",
    "video_player_win",
    "flutter_biometric",
    "forge_notification_bridge",
    "webview_flutter",
    "webview_windows"
  ],
  "children": [
    "dio_interceptor/AI_ANALYSIS.md",
    "usb_network/AI_ANALYSIS.md",
    "network_diagnostics/AI_ANALYSIS.md",
    "usb_detector/AI_ANALYSIS.md",
    "battery_monitor/AI_ANALYSIS.md",
    "bluetooth_ble/AI_ANALYSIS.md",
    "file_picker/AI_ANALYSIS.md",
    "online_video_player/AI_ANALYSIS.md",
    "biometric_auth/AI_ANALYSIS.md",
    "system_notification/AI_ANALYSIS.md",
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
