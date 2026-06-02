{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.platform.usb_detector",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/platform/usb_detector",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_routes.dart","module_root.dart","pages","widgets","state"],
  "owns": ["module_entry","module_ui","module_state","module_docs"],
  "depends": ["usb_serial","device_info_plus","module_registry"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["models/usb_device_info.dart","module_entry.dart","module_root.dart","services/usb_detection_service.dart"],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"]
}
