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
    "agent_takeover_ready",
    "pc_window_lifecycle_baseline",
    "pc_build_matrix"
  ],
  "dependency_migration": {
    "layout": "pub_workspace",
    "internal_packages": [
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
      "priority": 5,
      "status": "completed",
      "targets": [
        "desktop_multi_window",
        "file_picker_bridge",
        "usb_android_method_channel",
        "device_info_plus"
      ],
      "acceptance": [
        "android_support_matrix",
        "unsupported_fallbacks",
        "android_file_selector_mapping"
      ],
      "evidence": [
        "desktop_multi_window is gated out of Android navigation",
        "file_picker_bridge selects file_selector on Android",
        "usb_detector uses the Android usb_detector/usb MethodChannel",
        "device_info_plus is registered in GeneratedPluginRegistrant.java"
      ]
    },
    {
      "id": "usb_platform_boundary",
      "priority": 6,
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
      "priority": 7,
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
      "priority": 8,
      "status": "completed",
      "depends_on": [
        "module_platform_contract",
        "platform_plugin_audit"
      ],
      "acceptance": [
        "android_directory",
        "manifest_capabilities",
        "debug_apk",
        "emulator_smoke",
        "single_window_navigation"
      ],
      "evidence": [
        "Android host directory and USB host manifest feature exist",
        "debug APK builds and installs on API 35 emulator",
        "MainActivity reaches Fully drawn with a live process and no fatal log",
        "singleTop Activity and in-app NavigationPolicy keep Android single-window behavior"
      ]
    },
    {
      "id": "android_compatibility_plan",
      "priority": 9,
      "status": "planned",
      "depends_on": [
        "platform_plugin_audit",
        "usb_platform_boundary",
        "mobile_layout_baseline",
        "android_host"
      ],
      "phases": [
        "android_host_and_manifest",
        "platform_capability_fallbacks",
        "mobile_navigation_and_layout",
        "module_matrix_and_unavailable_states",
        "emulator_smoke_and_release_candidate"
      ],
      "acceptance": [
        "flutter_build_apk_debug",
        "android_emulator_smoke",
        "single_window_in_app_navigation",
        "unsupported_capability_state_visible",
        "no_android_analyzer_or_test_regressions"
      ]
    },
    {
      "id": "android_usb_permission_boundary",
      "priority": 10,
      "status": "completed",
      "depends_on": [
        "android_host"
      ],
      "targets": [
        "apps/flutter_forge/android/app/src/main/kotlin",
        "apps/flutter_forge/android/app/src/main/AndroidManifest.xml",
        "apps/flutter_forge/lib/modules/platform/usb_detector",
        "apps/flutter_forge/test/modules/platform/usb_detector"
      ],
      "acceptance": [
        "usb_permission_denied_is_observable",
        "device_enumeration_falls_back_without_crash",
        "android_usb_channel_contract_tested"
      ],
      "evidence": [
        "current Android MainActivity reports permission-safe USB enumeration",
        "USB service preserves devices when optional fields are unavailable",
        "Android USB service tests pass and APK builds successfully"
      ]
    },
    {
      "id": "module_scaffold_generation",
      "priority": 11,
      "status": "completed",
      "targets": [
        "tool/module_scaffold.dart",
        "tool/module_scaffold_test.dart"
      ],
      "acceptance": [
        "preview_does_not_write_formal_module",
        "apply_generates_module_entry_and_learning_page",
        "generated_analysis_contract_is_valid",
        "invalid_module_arguments_fail_with_usage_code",
        "route_registration_remains_explicit"
      ],
      "evidence": [
        "module_scaffold_test passes preview/apply and contract assertions",
        "dart analyze passes for scaffold CLI and acceptance test",
        "route registration remains outside scaffold automatic writes"
      ]
    },
    {
      "id": "pc_window_lifecycle_baseline",
      "priority": 3,
      "status": "completed",
      "targets": [
        "desktop_multi_window",
        "lib/shared/multi_window",
        "lib/app/category_navigation"
      ],
      "acceptance": [
        "three_category_windows",
        "close_reopen",
        "no_black_surface",
        "no_invalid_engine_handle"
      ]
    },
    {
      "id": "pc_build_matrix",
      "priority": 4,
      "status": "completed",
      "targets": [
        "macos",
        "windows"
      ],
      "acceptance": [
        "macos_release_build",
        "windows_release_build",
        "pc_quality_gate"
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
