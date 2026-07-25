{
  "schema": "flutter_study.agent_docs.project_context.v1",
  "consumer": "coding_agent",
  "package": {
    "name": "main_app",
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
    "next_host": "android",
    "target_hosts": [
      "android",
      "ios",
      "macos",
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
      "packages/gcode_core",
      "packages/flutter_study_learning",
      "packages/file_picker_bridge",
      "packages/flutter_ioc_core"
    ],
    "resolution_status": "blocked",
    "resolution_blocker": "test_analyzer_flutter_sdk_pin_conflict"
  },
  "internal_packages": [
    {
      "name": "gcode_core",
      "type": "flutter_package",
      "path": "packages/gcode_core",
      "entrypoint": "lib/gcode_core.dart"
    },
    {
      "name": "flutter_study_learning",
      "type": "flutter_package",
      "path": "packages/flutter_study_learning",
      "entrypoint": "lib/flutter_study_learning.dart"
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
    }
  ],
  "external_tools": [
    {
      "package": "flutterguard_cli",
      "source": "git",
      "url": "https://github.com/lizy-coding/flutterguard.git",
      "ref": "9f9be84a73dc4b99a956a8529b8c334849566b03",
      "immutable": true,
      "lock_status": "pending_dependency_resolution"
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
    "required_learning_dependency": "flutter_study_learning",
    "route_path_style": "kebab_case",
    "directory_style": "snake_case"
  },
  "platform_rules": {
    "router_platform_api": "forbidden",
    "module_host_navigation": "forbidden",
    "desktop_window_policy": "lib/app/category_navigation.dart",
    "platform_capability_contract": "business_neutral_interface"
  },
  "change_protocol": {
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
      "bash tool/generate_harness_ai_analysis.sh",
      "dart format .",
      "flutter analyze",
      "dart run flutterguard_cli:flutterguard scan . --fail-on high"
    ]
  }
}
