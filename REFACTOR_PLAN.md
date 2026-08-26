{
  "schema": "flutter_forge.agent_docs.refactor_plan.v1",
  "objective": "android_readiness_after_architecture_convergence",
  "active_phase": "agent_managed",
  "completed_milestones": [
    "directory_layers",
    "shared_package_extraction",
    "module_analysis_coverage",
    "app_navigation_boundary",
    "host_bootstrap_boundary",
    "workspace_package_import",
    "agent_takeover_ready"
  ],
  "dependency_migration": {
    "layout": "pub_workspace",
    "internal_packages": [
      "packages/gcode_core",
      "packages/flutter_study_learning",
      "packages/file_picker_bridge",
      "packages/flutter_ioc_core"
    ],
    "workspace_resolution_status": "active",
    "workspace_resolution_blocker": "none",
    "external_tool": {
      "package": "flutterguard_cli",
      "source": "git",
      "url": "https://github.com/lizy-coding/flutterguard.git",
      "ref": "9f9be84a73dc4b99a956a8529b8c334849566b03",
      "immutable": true,
      "lock_status": "git_pinned"
    }
  },
  "work_queue": [
    {
      "id": "module_platform_contract",
      "priority": 1,
      "status": "completed",
      "changes": [
        "ModuleEntry.platform_support",
        "ModuleHomePage.availability_state"
      ],
      "acceptance": [
        "catalog_platform_metadata_complete",
        "unsupported_module_state_visible"
      ]
    },
    {
      "id": "responsive_navigation_policy",
      "priority": 2,
      "status": "completed",
      "changes": [
        "NavigationPolicy",
        "CategoryNavigation.mobile_in_app_mode"
      ],
      "acceptance": [
        "android_ios_web_in_app_navigation",
        "compact_width_in_app_navigation",
        "desktop_large_window_policy_test"
      ]
    },
    {
      "id": "platform_plugin_audit",
      "priority": 3,
      "status": "pending",
      "targets": [
        "desktop_multi_window",
        "file_picker_bridge",
        "usb_serial",
        "device_info_plus"
      ],
      "acceptance": [
        "android_support_matrix",
        "unsupported_fallbacks"
      ]
    },
    {
      "id": "usb_platform_boundary",
      "priority": 4,
      "status": "pending",
      "targets": [
        "lib/modules/platform/usb_detector"
      ],
      "acceptance": [
        "no_windows_hardcode",
        "android_system_info",
        "error_branch_test"
      ]
    },
    {
      "id": "mobile_layout_baseline",
      "priority": 5,
      "status": "pending",
      "viewport_width_dp": 360,
      "targets": [
        "module_home",
        "category_home",
        "ready_modules",
        "recommended_modules"
      ],
      "acceptance": [
        "no_overflow",
        "safe_area",
        "keyboard_avoidance",
        "touch_targets"
      ]
    },
    {
      "id": "android_host",
      "priority": 6,
      "status": "blocked_by_dependencies",
      "depends_on": [
        "module_platform_contract",
        "platform_plugin_audit",
        "mobile_layout_baseline"
      ],
      "acceptance": [
        "android_directory",
        "manifest_capabilities",
        "debug_apk",
        "emulator_smoke"
      ]
    }
  ],
  "quality_gate": [
    "node tool/validate_agent_docs.js",
    "dart format .",
    "flutter analyze:no_error",
    "flutterguard:no_high",
    "logic_change:targeted_test",
    "teaching_ui_change:visual_evidence"
  ],
  "deferred_queue": [
    "popup_widgets_decomposition",
    "widget_test_coverage",
    "flutterguard_med_reduction",
    "recommended_module_visual_evidence"
  ]
}
