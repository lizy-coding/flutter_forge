{
  "schema": "flutter_forge.agent_docs.project_context.v1",
  "consumer": "coding_agent",
  "package": {
    "name": "flutter_forge_app",
    "type": "flutter_modular_learning_app",
    "sdk": [
      "flutter_3",
      "dart_3"
    ]
  },
  "platform": {
    "current_hosts": [
      "android",
      "macos",
      "web",
      "windows"
    ],
    "host_evidence_semantics": "directory_presence_only",
    "target_hosts": [
      "android",
      "ios",
      "macos",
      "web",
      "windows"
    ]
  },
  "entrypoints": {
    "process": "lib/main.dart",
    "bootstrap": "lib/app/app_bootstrap.dart",
    "app": "lib/app/app.dart",
    "router": "lib/app/router/app_router.dart",
    "route_table": "lib/app/router/app_route_table.dart",
    "module_manifest": "lib/module_registry/module_manifest.dart"
  },
  "repository": {
    "layout": "pub_workspace",
    "workspace_root": ".",
    "members": [
      "apps/flutter_forge",
      "packages/file_picker_bridge",
      "packages/flutter_ioc_core",
      "packages/desktop_multi_window",
      "packages/flutter_battery",
      "packages/usb_network_bridge",
      "packages/forge_scene_viewer"
    ],
    "resolution_status": "active",
    "resolution_blocker": "none"
  },
  "internal_packages": [
    {
      "name": "forge_scene_viewer",
      "type": "flutter_package",
      "path": "packages/forge_scene_viewer",
      "entrypoint": "lib/forge_scene_viewer.dart"
    },
    {
      "name": "usb_network_bridge",
      "type": "flutter_plugin_package",
      "path": "packages/usb_network_bridge",
      "entrypoint": "lib/usb_network_bridge.dart"
    },
    {
      "name": "flutter_battery",
      "type": "flutter_plugin_package",
      "path": "packages/flutter_battery",
      "entrypoint": "lib/flutter_battery.dart"
    },
    {
      "name": "file_picker_bridge",
      "type": "flutter_bridge_package",
      "path": "packages/file_picker_bridge",
      "entrypoint": "lib/file_picker_bridge.dart"
    },
    {
      "name": "flutter_ioc_core",
      "type": "dart_package",
      "path": "packages/flutter_ioc_core",
      "entrypoint": "lib/flutter_ioc_core.dart"
    },
    {
      "name": "desktop_multi_window",
      "type": "flutter_plugin_package",
      "path": "packages/desktop_multi_window",
      "entrypoint": "lib/desktop_multi_window.dart"
    }
  ],
  "external_packages": [
    {
      "name": "gcode_core",
      "source": "git",
      "url": "https://github.com/lizy-coding/gcode_core.git",
      "ref": "v0.2.1",
      "resolved_ref": "22d76ad54e11ad752771b594b8345d5f9aab6a31",
      "entrypoint": "lib/gcode_core.dart",
      "flutter_min": "3.47.2",
      "entry_platforms": [
        "macOS"
      ],
      "requires": [
        "impeller",
        "flutter_gpu"
      ],
      "macos_deployment_target_min": "12.0"
    }
  ],
  "capability_aliases": {
    "shared_learning": "lib/shared/learning",
    "shared_popup": "lib/shared/popup",
    "shared_table": "lib/shared/table"
  },
  "external_tools": [],
  "layers": [
    {
      "id": "app",
      "path": "lib/app",
      "owns": [
        "host_bootstrap",
        "app_shell",
        "navigation_policy",
        "route_composition"
      ],
      "may_depend_on": [
        "module_registry",
        "shared",
        "modules"
      ]
    },
    {
      "id": "module_registry",
      "path": "lib/module_registry",
      "owns": [
        "module_metadata",
        "platform_snapshot",
        "catalog_operations"
      ],
      "may_depend_on": [
        "flutter",
        "go_router"
      ],
      "assembly_exception": "lib/module_registry/module_manifest.dart"
    },
    {
      "id": "shared",
      "path": "lib/shared",
      "owns": [
        "business_neutral_capabilities",
        "platform_boundaries"
      ],
      "forbidden_dependencies": [
        "app",
        "modules"
      ]
    },
    {
      "id": "modules",
      "path": "lib/modules/{category}/{module}",
      "owns": [
        "learning_ui",
        "module_state",
        "module_domain",
        "module_data"
      ],
      "forbidden_dependencies": [
        "other_modules"
      ]
    }
  ],
  "module_contract": {
    "required_files": [
      "module_entry.dart",
      "AI_ANALYSIS.md"
    ],
    "required_registration": "lib/module_registry/module_manifest.dart",
    "required_metadata": [
      "category",
      "difficulty",
      "concepts",
      "estimatedMinutes",
      "status",
      "subtitle"
    ],
    "required_learning_dependency": "shared_learning",
    "route_path_style": "kebab_case",
    "directory_style": "snake_case"
  },
  "platform_rules": {
    "router_platform_api": "forbidden",
    "module_host_navigation": "forbidden",
    "desktop_window_policy": "lib/app/category_navigation.dart",
    "navigation_policy": "lib/app/navigation_policy.dart",
    "compact_width_breakpoint_dp": 600,
    "desktop_shell": {
      "targets": [
        "macos",
        "windows"
      ],
      "rendering": "shared_flutter_workbench",
      "titlebar": "immersive_flutter_48dp_with_native_window_controls",
      "titlebar_home": "main_workbench_or_focused_category_root",
      "titlebar_double_click": "platform_system_preference",
      "window_controls": "native_macos_leading_traffic_lights_windows_trailing_caption",
      "fullscreen_entry": "separate_native_fullscreen_button_and_f11",
      "native_control_layout": "host_reported_logical_insets",
      "window_host": "lib/app/desktop_window_host.dart",
      "native_hosts": [
        "macos/Runner/AppDelegate.swift",
        "windows/runner/desktop_window_host.cpp"
      ],
      "default_home": "workbench_recent_and_categories",
      "navigation": "two_level_category_module_single_active_route",
      "quick_open": "title_subtitle_category_concepts",
      "recent_history": "bounded_module_entry_preferences_not_task_restore",
      "default_palette": "liquidGlass_on_first_desktop_launch_preserving_saved_choice",
      "glass_scope": "native_basic_pages_solid_teaching_minimal_titlebar",
      "material_backend": "per_engine_DesktopWindowHost_native_extension",
      "macos_material": "NSVisualEffectView_sidebar_behindWindow",
      "windows_material": "public_DWM_mica_windows11_22h2_else_solid",
      "main_window_close": "exit_application",
      "category_window_close": "close_current_window",
      "decision": "docs/adr/0018-platform-interaction-and-native-materials.md",
      "window_decision": "docs/adr/0016-shared-desktop-workbench.md"
    },
    "mobile_window_policy": "in_app_navigation_only",
    "web_window_policy": "in_app_navigation_only",
    "web_mobile_home": "search_categories_recent_with_creator_about",
    "web_mobile_default_palette": "graphiteForge_preserving_saved_choice",
    "search_fields": [
      "title",
      "subtitle",
      "category",
      "concepts"
    ],
    "session_return_state": "query_category_scroll",
    "web_history": "router_urls_reflect_imperative_navigation",
    "platform_snapshot": "bootstrap_initialized_process_immutable",
    "target_platforms": [
      "android",
      "ios",
      "macos",
      "web",
      "windows"
    ],
    "non_target_platforms": "unsupported",
    "module_platform_semantics": "target_platform_entry_open_unless_excluded",
    "unsupported_route": "stable_guarded_module_route",
    "web_release_build": "bash tool/build_web_release.sh",
    "web_startup_shell": "web/index.html + web/flutter_bootstrap.js",
    "platform_capability_contract": "business_neutral_interface",
    "availability_source": "tool/agent_indexes/availability.js",
    "maintenance_semantics": "support_declarations_and_known_constraints",
    "maintenance_matrix": "docs/module_availability/matrix.json",
    "historical_reports": "docs/module_availability/archive/README.md"
  },
  "interaction_direction": {
    "decision": "docs/adr/0018-platform-interaction-and-native-materials.md",
    "status": "accepted",
    "implementation_status": "implemented_platform_validation_partial",
    "current_implementation": "platform_rules_and_layer_contracts",
    "desktop": {
      "primary_use": "keyboard_mouse_learning_and_experiments",
      "basic_pages": [
        "workbench_home",
        "category_catalog",
        "about"
      ],
      "page_classification": "semantic_role_not_url_depth",
      "default_material": "native_material_follow_system_with_user_opt_out",
      "macos_material": "validate_system_visual_effect",
      "windows_material": "validate_windows11_mica_else_solid",
      "mica_semantics": "opaque_wallpaper_tint_not_behind_window_transparency",
      "fallback": "solid_on_unsupported_error_system_transparency_off_or_high_contrast",
      "preference_migration": "preserve_explicit_solid_and_brightness",
      "teaching_surfaces": "solid_content_experiment_and_sidebar_minimal_titlebar_material",
      "window_control_owner": "existing_DesktopWindowHost",
      "material_integration": "per_engine_native_extension_after_flutter_acrylic_evaluation",
      "candidate_rejection": "macos_window_utils_process_global_main_window_and_reset_side_effects"
    },
    "web_mobile": {
      "home_order": [
        "search",
        "categories",
        "recent_modules"
      ],
      "creator_profile": "about",
      "default_surface": "solid",
      "mobile_primary_use": "quick_reference",
      "mobile_navigation": "home_category_teaching_without_new_bottom_tabs",
      "web_navigation": "stable_urls_browser_history_explicit_new_tab"
    },
    "search_fields": [
      "title",
      "subtitle",
      "category",
      "concepts"
    ],
    "return_state": "session_query_category_and_scroll",
    "persisted_history": "module_entries_not_experiment_restore",
    "scope": "app_entry_navigation_surfaces_reading_container_and_blocking_overflow",
    "teaching_content": "shared_existing_content_internal_relayout_deferred"
  },
  "change_protocol": {
    "branch_policy": {
      "development_branch": "dev",
      "stable_branch": "master",
      "stable_branch_update": "pull_request_from_dev_only",
      "stable_branch_direct_push": "forbidden",
      "stable_branch_force_push": "forbidden",
      "stable_branch_delete": "forbidden",
      "required_status_check": "quality-gate",
      "required_approvals": 0,
      "required_approvals_reason": "single_maintainer_self_review_deadlock",
      "sync_after_merge": "merge_master_topology_back_into_dev"
    },
    "pre_read": [
      "AI_PROJECT_CONTEXT.md",
      "REFACTOR_PLAN.md",
      "{target}/AI_ANALYSIS.md"
    ],
    "update_source": [
      "tool/generate_agent_indexes.js",
      "tool/agent_indexes/catalog.js",
      "tool/agent_indexes/project.js",
      "tool/agent_indexes/plan.js",
      "tool/agent_indexes/generator.js",
      "tool/agent_indexes/contracts.js",
      "tool/agent_indexes/routes.js",
      "tool/agent_indexes/availability.js",
      "tool/agent_indexes/support.js"
    ],
    "generate": "bash tool/generate_harness_ai_analysis.sh",
    "validate": [
      "bash tool/check_generated_docs.sh",
      "dart format --output=none --set-exit-if-changed .",
      "flutter analyze (bare)",
      "bash tool/test_all.sh",
      "bash tool/verify_test_layout.sh",
      "bash tool/build_web_release.sh"
    ],
    "ci": {
      "authoritative_remote_packaging_gate": ".github/workflows/ci.yml",
      "analyze_standard": "bare flutter analyze (info/warning treated as failure)",
      "steps": [
        "flutter pub get --enforce-lockfile",
        "bash tool/quality_gate.sh"
      ],
      "implementation": "bash tool/quality_gate.sh; no FlutterGuard dependency"
    }
  }
}
