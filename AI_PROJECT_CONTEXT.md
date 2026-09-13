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
      "macos",
      "windows"
    ],
    "next_host": "web",
    "target_hosts": [
      "android",
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
    "route_table": "lib/app/router/app_route_table.dart"
  },
  "repository": {
    "layout": "pub_workspace",
    "workspace_root": ".",
    "members": [
      "packages/file_picker_bridge",
      "packages/flutter_ioc_core",
      "packages/desktop_multi_window"
    ],
    "resolution_status": "active",
    "resolution_blocker": "none"
  },
  "internal_packages": [
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
      "ref": "v0.2.0-dev.1",
      "entrypoint": "lib/gcode_core.dart",
      "flutter_min": "3.47.2",
      "supported_platforms": [
        "macOS"
      ],
      "requires": [
        "impeller",
        "flutter_gpu"
      ],
      "macos_deployment_target_min": "12.0"
    }
  ],
  "external_tools": [
    {
      "package": "flutterguard_cli",
      "source": "git",
      "url": "https://github.com/lizy-coding/flutterguard.git",
      "ref": "9f9be84a73dc4b99a956a8529b8c334849566b03",
      "immutable": true,
      "lock_status": "git_pinned"
    }
  ],
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
        "catalog_operations"
      ],
      "may_depend_on": [
        "flutter",
        "go_router"
      ]
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
    "required_registration": "lib/app/router/app_route_table.dart",
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
    "mobile_window_policy": "in_app_navigation_only",
    "web_window_policy": "in_app_navigation_only",
    "web_platform_detection": "kIsWeb_before_defaultTargetPlatform",
    "web_release_build": "bash tool/build_web_release.sh",
    "web_startup_shell": "web/index.html + web/flutter_bootstrap.js",
    "platform_capability_contract": "business_neutral_interface"
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
      "tool/generate_agent_indexes.js"
    ],
    "generate": "bash tool/generate_harness_ai_analysis.sh",
    "validate": [
      "bash tool/generate_harness_ai_analysis.sh + git diff --exit-code",
      "dart format . + git diff --exit-code -- *.dart",
      "flutter analyze (bare)",
      "bash tool/test_all.sh",
      "bash tool/verify_test_layout.sh",
      "bash tool/build_web_release.sh",
      "dart run flutterguard_cli:flutterguard scan . --fail-on high (cd apps/flutter_forge)"
    ],
    "ci": {
      "authoritative_remote_packaging_gate": ".github/workflows/ci.yml",
      "analyze_standard": "bare flutter analyze (info/warning treated as failure)",
      "steps": [
        "flutter pub get",
        "agent doc generation + drift check",
        "dart format + drift check",
        "flutter analyze (bare)",
        "bash tool/test_all.sh"
      ],
      "flutterguard": "not run in CI (previously failed from repo root with empty match); enforced only by local quality_gate.sh stage 6"
    }
  }
}
