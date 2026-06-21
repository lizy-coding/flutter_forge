{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "flutter_study.root",
    "kind": "app_workspace",
    "package": "main_app",
    "path": ".",
    "status": "active"
  },
  "entrypoints": [
    "lib/main.dart",
    "lib/app/app.dart",
    "lib/app/router/app_route_table.dart"
  ],
  "architecture_layers": [
    {
      "path": "lib/app",
      "role": "app_shell",
      "owns": ["material_app_router", "go_router_root", "module_home_index"],
      "analysis": ["lib/app/router/AI_ANALYSIS.md"]
    },
    {
      "path": "lib/module_registry",
      "role": "module_metadata_contract",
      "owns": ["module_entry", "module_category", "difficulty", "module_status"],
      "analysis": []
    },
    {
      "path": "lib/shared",
      "role": "business_free_shared_capabilities",
      "owns": ["multi_window", "platform_boundary"],
      "analysis": [
        "lib/shared/AI_ANALYSIS.md",
        "lib/shared/multi_window/AI_ANALYSIS.md",
        "lib/shared/platform/AI_ANALYSIS.md"
      ]
    },
    {
      "path": "lib/modules",
      "role": "learning_modules",
      "owns": ["basic", "async", "state", "ui", "popup_table", "platform"],
      "analysis": ["lib/AI_MODULE_INDEX.md", "lib/modules/**/AI_ANALYSIS.md"]
    },
    {
      "path": "macos",
      "role": "host_platform_integration",
      "owns": ["desktop_runner", "multi_window_host", "file_picker_bridge_wiring"],
      "analysis": ["lib/shared/platform/AI_ANALYSIS.md"]
    }
  ],
  "module_summary": {
    "total_registered": 17,
    "by_category": {
      "basic": 3,
      "async": 3,
      "state": 2,
      "ui": 3,
      "popup_table": 4,
      "platform": 2
    },
    "by_status": {
      "recommended": 4,
      "ready": 13,
      "pending": 0
    },
    "required_route_table": "lib/app/router/app_route_table.dart",
    "required_index": "lib/AI_MODULE_INDEX.md"
  },
  "external_packages": [
    "../gcode_core",
    "../flutter_study_learning",
    "../file_picker_bridge",
    "../flutter_ioc_core",
    "../flutterguard/packages/flutterguard_cli"
  ],
  "next_direction": [
    {
      "priority": 1,
      "id": "stabilize_analysis_hierarchy",
      "scope": [
        "AI_ANALYSIS.md",
        "lib/AI_MODULE_INDEX.md",
        "tool/generate_harness_ai_analysis.sh"
      ],
      "actions": ["sync_schema", "remove_file_inventory", "enforce_layer_scope"],
      "blocks": ["analysis_drift"]
    },
    {
      "priority": 2,
      "id": "split_large_popup_widgets",
      "scope": ["lib/modules/popup_table/popup_widgets"],
      "actions": ["split_module_root", "extract_widgets", "add_smoke_test"],
      "blocks": ["large_file", "flutterguard_noise"]
    },
    {
      "priority": 3,
      "id": "raise_recommended_modules",
      "scope": ["module_status_ready", "learning_scaffold_modules"],
      "actions": ["verify_metadata", "verify_ai_analysis", "add_widget_smoke_tests"],
      "blocks": ["status_inflation"]
    },
    {
      "priority": 4,
      "id": "shared_boundary_tests",
      "scope": ["lib/shared/multi_window", "../file_picker_bridge"],
      "actions": ["add_platform_mocks", "add_cancel_tests", "add_error_tests"],
      "blocks": ["shared_regression"]
    },
    {
      "priority": 5,
      "id": "quality_noise_reduction",
      "scope": ["flutterguard_medium_low", "module_widget_tests"],
      "actions": ["triage_medium_low", "add_module_tests", "record_visual_acceptance"],
      "blocks": ["quality_debt"]
    }
  ],
  "update_policy": {
    "syntax": "json_config",
    "prose": "forbidden",
    "markdown": "forbidden",
    "root_file": ["layers", "module_totals", "package_boundaries", "next_direction"],
    "layer_files": ["ownership", "entrypoints", "dependencies", "contracts", "validation"],
    "module_files": ["structure", "data_flow", "key_classes", "teaching_components", "change_notes"],
    "avoid": ["root_file_inventory", "module_internal_duplication"]
  },
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": [
    "dart format .",
    "flutter analyze",
    "dart run flutterguard_cli:flutterguard scan --path . --fail-on high"
  ]
}
