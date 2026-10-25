{
  "schema": "flutter_forge.agent_docs.module_index.v1",
  "registry": "lib/module_registry/module_manifest.dart",
  "count": 35,
  "modules": [
    {
      "id": "graphics_background",
      "category": "basic",
      "path": "lib/modules/basic/graphics_background",
      "route": "/graphics-background",
      "status": "ready",
      "depends": [
        "shared_learning",
        "go_router"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/basic/graphics_background/AI_ANALYSIS.md"
    },
    {
      "id": "pixel_shader_intro",
      "category": "basic",
      "path": "lib/modules/basic/pixel_shader_intro",
      "route": "/pixel-shader-intro",
      "status": "ready",
      "depends": [
        "shared_learning",
        "go_router"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/basic/pixel_shader_intro/AI_ANALYSIS.md"
    },
    {
      "id": "constraint_layout",
      "category": "basic",
      "path": "lib/modules/basic/constraint_layout",
      "route": "/constraint-layout",
      "status": "ready",
      "depends": [
        "shared_learning",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/basic/constraint_layout/AI_ANALYSIS.md"
    },
    {
      "id": "tree_state",
      "category": "basic",
      "path": "lib/modules/basic/tree_state",
      "route": "/tree-state",
      "status": "recommended",
      "depends": [
        "shared_learning",
        "module_registry",
        "go_router"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/basic/tree_state/AI_ANALYSIS.md"
    },
    {
      "id": "microtask",
      "category": "basic",
      "path": "lib/modules/basic/microtask",
      "route": "/microtask",
      "status": "recommended",
      "depends": [
        "shared_learning",
        "module_registry",
        "go_router"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/basic/microtask/AI_ANALYSIS.md"
    },
    {
      "id": "debounce_throttle",
      "category": "basic",
      "path": "lib/modules/basic/debounce_throttle",
      "route": "/debounce-throttle",
      "status": "ready",
      "depends": [
        "shared_learning",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/basic/debounce_throttle/AI_ANALYSIS.md"
    },
    {
      "id": "stream_subscription",
      "category": "async",
      "path": "lib/modules/async/stream_subscription",
      "route": "/stream-subscription",
      "status": "recommended",
      "depends": [
        "shared_learning",
        "module_registry",
        "go_router"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/async/stream_subscription/AI_ANALYSIS.md"
    },
    {
      "id": "isolate_basic",
      "category": "async",
      "path": "lib/modules/async/isolate_basic",
      "route": "/isolate-basic",
      "status": "ready",
      "depends": [
        "shared_learning",
        "module_registry",
        "go_router"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "web"
        ],
        "required_capabilities": [
          "isolates"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "isolates",
            "reason": "safari_isolate_progress_unreliable",
            "sources": [
              "apps/flutter_forge/lib/modules/async/isolate_basic",
              "apps/flutter_forge/lib/modules/async/isolate_task_manager"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/async/isolate_basic/AI_ANALYSIS.md"
    },
    {
      "id": "isolate_task_manager",
      "category": "async",
      "path": "lib/modules/async/isolate_task_manager",
      "route": "/isolate-stream",
      "status": "ready",
      "depends": [
        "shared_learning",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "web"
        ],
        "required_capabilities": [
          "isolates"
        ],
        "unreviewed_dependencies": [
          "collection"
        ],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "isolates",
            "reason": "safari_isolate_progress_unreliable",
            "sources": [
              "apps/flutter_forge/lib/modules/async/isolate_basic",
              "apps/flutter_forge/lib/modules/async/isolate_task_manager"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/async/isolate_task_manager/AI_ANALYSIS.md"
    },
    {
      "id": "status_management",
      "category": "state",
      "path": "lib/modules/state/status_management",
      "route": "/status-management",
      "status": "recommended",
      "depends": [
        "shared_learning",
        "provider",
        "flutter_riverpod",
        "flutter_bloc",
        "module_registry",
        "go_router"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [
          "equatable"
        ],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/state/status_management/AI_ANALYSIS.md"
    },
    {
      "id": "flutter_ioc",
      "category": "state",
      "path": "lib/modules/state/flutter_ioc",
      "route": "/flutter-ioc",
      "status": "ready",
      "depends": [
        "shared_learning",
        "flutter_ioc_core",
        "provider",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/state/flutter_ioc/AI_ANALYSIS.md"
    },
    {
      "id": "local_persistence",
      "category": "state",
      "path": "lib/modules/state/local_persistence",
      "route": "/local-persistence",
      "status": "ready",
      "depends": [
        "shared_learning",
        "shared_preferences",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/state/local_persistence/AI_ANALYSIS.md"
    },
    {
      "id": "gcode_visualizer",
      "category": "ui",
      "path": "lib/modules/ui/gcode_visualizer",
      "route": "/gcode-visualizer",
      "status": "ready",
      "depends": [
        "shared_learning",
        "gcode_core",
        "file_picker_bridge",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "android",
          "iOS",
          "web",
          "windows"
        ],
        "required_capabilities": [
          "gcode_render",
          "file_selection"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "gcode_render",
            "reason": "macos_gcode_adapter_only",
            "sources": [
              "apps/flutter_forge/lib/modules/ui/gcode_visualizer/module_entry.dart",
              "apps/flutter_forge/pubspec.yaml"
            ]
          },
          {
            "capability": "file_selection",
            "reason": "file_bridge_adapters_web_filename_only",
            "sources": [
              "packages/file_picker_bridge/lib/file_picker_bridge.dart"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/ui/gcode_visualizer/AI_ANALYSIS.md"
    },
    {
      "id": "adsorption_line",
      "category": "ui",
      "path": "lib/modules/ui/adsorption_line",
      "route": "/adsorption-line",
      "status": "ready",
      "depends": [
        "shared_learning",
        "provider",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/ui/adsorption_line/AI_ANALYSIS.md"
    },
    {
      "id": "download_animation",
      "category": "ui",
      "path": "lib/modules/ui/download_animation",
      "route": "/download-animation",
      "status": "ready",
      "depends": [
        "shared_learning",
        "module_registry",
        "go_router"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [
          "flutter_svg"
        ],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/ui/download_animation/AI_ANALYSIS.md"
    },
    {
      "id": "font_picker",
      "category": "ui",
      "path": "lib/modules/ui/font_picker",
      "route": "/font-picker",
      "status": "ready",
      "depends": [
        "shared_learning",
        "file_picker_bridge",
        "module_registry",
        "go_router"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [
          "font_file_import"
        ],
        "reasons": [
          {
            "capability": "font_file_import",
            "reason": "font_import_requires_native_bytes_and_file_bridge",
            "sources": [
              "apps/flutter_forge/lib/modules/ui/font_picker/pages/font_picker_page.dart",
              "apps/flutter_forge/lib/modules/ui/font_picker/pages/font_picker_web_page.dart"
            ]
          }
        ],
        "restriction": null,
        "features": {
          "font_file_import": {
            "platforms": [
              "android",
              "macOS",
              "windows"
            ],
            "reason": "font_import_requires_native_bytes_and_file_bridge",
            "sources": [
              "apps/flutter_forge/lib/modules/ui/font_picker/pages/font_picker_page.dart",
              "apps/flutter_forge/lib/modules/ui/font_picker/pages/font_picker_web_page.dart"
            ]
          },
          "font_preview": {
            "platforms": [
              "android",
              "iOS",
              "macOS",
              "windows"
            ],
            "reason": "web_font_page_has_no_native_preview_controls",
            "sources": [
              "apps/flutter_forge/lib/modules/ui/font_picker/pages/font_picker_web_page.dart"
            ]
          }
        }
      },
      "analysis": "lib/modules/ui/font_picker/AI_ANALYSIS.md"
    },
    {
      "id": "genui_workbench",
      "category": "ui",
      "path": "lib/modules/ui/genui_workbench",
      "route": "/genui-workbench",
      "status": "ready",
      "depends": [
        "shared_learning",
        "genui",
        "a2ui_core",
        "json_schema_builder",
        "dio"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [
          "genui_surface"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "genui_surface",
            "reason": "bounded_flutter_catalog_and_http_stream_no_native_model_runtime",
            "sources": [
              "apps/flutter_forge/lib/modules/ui/genui_workbench/workbench_catalog.dart",
              "apps/flutter_forge/lib/modules/ui/genui_workbench/workbench_source.dart",
              "apps/flutter_forge/pubspec.yaml"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/ui/genui_workbench/AI_ANALYSIS.md"
    },
    {
      "id": "workflow_workbench",
      "category": "ui",
      "path": "lib/modules/ui/workflow_workbench",
      "route": "/workflow-workbench",
      "status": "ready",
      "depends": [
        "shared_learning",
        "shared_table",
        "shared_workflows",
        "forge_articles",
        "genui",
        "a2ui_core",
        "json_schema_builder",
        "dio"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [
          "article_workflow",
          "genui_surface"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "article_workflow",
            "reason": "pure_dart_article_request_and_teaching_adapter",
            "sources": [
              "packages/forge_articles/pubspec.yaml",
              "packages/forge_articles/lib/forge_articles.dart"
            ]
          },
          {
            "capability": "genui_surface",
            "reason": "bounded_flutter_catalog_and_http_stream_no_native_model_runtime",
            "sources": [
              "apps/flutter_forge/lib/modules/ui/genui_workbench/workbench_catalog.dart",
              "apps/flutter_forge/lib/modules/ui/genui_workbench/workbench_source.dart",
              "apps/flutter_forge/pubspec.yaml"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/ui/workflow_workbench/AI_ANALYSIS.md"
    },
    {
      "id": "shader_playground",
      "category": "ui",
      "path": "lib/modules/ui/shader_playground",
      "route": "/shader-playground",
      "status": "ready",
      "depends": [
        "shared_learning",
        "go_router"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [
          "fragment_shader_canvas"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "fragment_shader_canvas",
            "reason": "sdk_fragment_program_canvas_skia_impeller",
            "sources": [
              "apps/flutter_forge/lib/modules/ui/shader_playground/shader_preview.dart",
              "apps/flutter_forge/pubspec.yaml"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/ui/shader_playground/AI_ANALYSIS.md"
    },
    {
      "id": "flutter_scene_3d",
      "category": "ui",
      "path": "lib/modules/ui/flutter_scene_3d",
      "route": "/flutter-scene-3d",
      "status": "ready",
      "depends": [
        "shared_learning",
        "forge_scene_viewer",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "iOS",
          "web"
        ],
        "required_capabilities": [
          "scene_render"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "scene_render",
            "reason": "scene_gpu_adapters",
            "sources": [
              "packages/forge_scene_viewer/lib/src/scene_runtime.dart",
              "apps/flutter_forge/android/app/src/main/AndroidManifest.xml",
              "apps/flutter_forge/windows/runner/main.cpp",
              "apps/flutter_forge/lib/modules/ui/flutter_scene_3d/module_entry.dart"
            ]
          }
        ],
        "restriction": null,
        "features": {
          "scene_controls": {
            "platforms": [
              "macOS",
              "windows"
            ],
            "reason": "desktop_scene_controls_android_view_only",
            "sources": [
              "apps/flutter_forge/lib/modules/ui/flutter_scene_3d/scene_interaction_mode.dart"
            ]
          }
        }
      },
      "analysis": "lib/modules/ui/flutter_scene_3d/AI_ANALYSIS.md"
    },
    {
      "id": "popup_widgets",
      "category": "popup_table",
      "path": "lib/modules/popup_table/popup_widgets",
      "route": "/popup-widgets",
      "status": "ready",
      "depends": [
        "shared_learning",
        "shared_popup",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/popup_table/popup_widgets/AI_ANALYSIS.md"
    },
    {
      "id": "popup_list_interaction",
      "category": "popup_table",
      "path": "lib/modules/popup_table/popup_list_interaction",
      "route": "/popup-list-interaction",
      "status": "ready",
      "depends": [
        "shared_learning",
        "shared_popup",
        "shared_table",
        "module_registry",
        "go_router"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/popup_table/popup_list_interaction/AI_ANALYSIS.md"
    },
    {
      "id": "scroll_table",
      "category": "popup_table",
      "path": "lib/modules/popup_table/scroll_table",
      "route": "/scroll-table",
      "status": "ready",
      "depends": [
        "shared_learning",
        "shared_table",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/popup_table/scroll_table/AI_ANALYSIS.md"
    },
    {
      "id": "overlay_follow_compare",
      "category": "popup_table",
      "path": "lib/modules/popup_table/overlay_follow_compare",
      "route": "/overlay-compare",
      "status": "ready",
      "depends": [
        "shared_learning",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/popup_table/overlay_follow_compare/AI_ANALYSIS.md"
    },
    {
      "id": "dio_interceptor",
      "category": "platform",
      "path": "lib/modules/platform/dio_interceptor",
      "route": "/dio-interceptor",
      "status": "ready",
      "depends": [
        "shared_learning",
        "dio",
        "forge_articles",
        "module_registry",
        "go_router"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [],
        "required_capabilities": [
          "article_workflow"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "article_workflow",
            "reason": "pure_dart_article_request_and_teaching_adapter",
            "sources": [
              "packages/forge_articles/pubspec.yaml",
              "packages/forge_articles/lib/forge_articles.dart"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/platform/dio_interceptor/AI_ANALYSIS.md"
    },
    {
      "id": "usb_network",
      "category": "platform",
      "path": "lib/modules/platform/usb_network",
      "route": "/usb-network",
      "status": "pending",
      "depends": [
        "shared_learning",
        "usb_network_bridge"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "android",
          "iOS",
          "web"
        ],
        "required_capabilities": [
          "usb_network"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "usb_network",
            "reason": "desktop_system_ncm_interface_bound_tcp",
            "sources": [
              "packages/usb_network_bridge/pubspec.yaml",
              "packages/usb_network_bridge/lib/src/backend_native.dart"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/platform/usb_network/AI_ANALYSIS.md"
    },
    {
      "id": "network_diagnostics",
      "category": "platform",
      "path": "lib/modules/platform/network_diagnostics",
      "route": "/network-diagnostics",
      "status": "pending",
      "depends": [
        "shared_learning"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "android",
          "iOS",
          "web"
        ],
        "required_capabilities": [
          "desktop_network_diagnostics"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "desktop_network_diagnostics",
            "reason": "desktop_direct_network_probes_mobile_deferred_web_out_of_scope",
            "sources": [
              "apps/flutter_forge/lib/modules/platform/network_diagnostics/desktop_network_probe.dart",
              "docs/NETWORK_DIAGNOSTICS_DESIGN.md"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/platform/network_diagnostics/AI_ANALYSIS.md"
    },
    {
      "id": "usb_detector",
      "category": "platform",
      "path": "lib/modules/platform/usb_detector",
      "route": "/usb-detector",
      "status": "ready",
      "depends": [
        "shared_learning",
        "usb_detector_bridge",
        "device_info_plus",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "required_capabilities": [
          "usb_detection"
        ],
        "unreviewed_dependencies": [
          "device_info_plus"
        ],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "usb_detection",
            "reason": "android_usb_manager_enumeration_only",
            "sources": [
              "packages/usb_detector_bridge/pubspec.yaml",
              "packages/usb_detector_bridge/lib/usb_detector_method_channel.dart"
            ]
          }
        ],
        "restriction": {
          "reason": "usb_otg_learning_workflow_deferred",
          "sources": [
            "tool/agent_indexes/plan.js"
          ]
        },
        "features": {}
      },
      "analysis": "lib/modules/platform/usb_detector/AI_ANALYSIS.md"
    },
    {
      "id": "battery_monitor",
      "category": "platform",
      "path": "lib/modules/platform/battery_monitor",
      "route": "/battery-monitor",
      "status": "ready",
      "depends": [
        "shared_learning",
        "flutter_battery",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "iOS",
          "web",
          "windows"
        ],
        "required_capabilities": [
          "battery_monitor"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "battery_monitor",
            "reason": "battery_android_macos_native_adapters",
            "sources": [
              "packages/flutter_battery/pubspec.yaml",
              "apps/flutter_forge/lib/modules/platform/battery_monitor/module_entry.dart"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/platform/battery_monitor/AI_ANALYSIS.md"
    },
    {
      "id": "bluetooth_ble",
      "category": "platform",
      "path": "lib/modules/platform/bluetooth_ble",
      "route": "/bluetooth-ble",
      "status": "ready",
      "depends": [
        "shared_learning",
        "universal_ble",
        "url_launcher",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "iOS",
          "web"
        ],
        "required_capabilities": [
          "ble_central"
        ],
        "unreviewed_dependencies": [
          "url_launcher"
        ],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "ble_central",
            "reason": "ble_central_adapters",
            "sources": [
              "apps/flutter_forge/lib/modules/platform/bluetooth_ble/module_entry.dart",
              "apps/flutter_forge/lib/modules/platform/bluetooth_ble/state/ble_session.dart"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/platform/bluetooth_ble/AI_ANALYSIS.md"
    },
    {
      "id": "file_picker",
      "category": "platform",
      "path": "lib/modules/platform/file_picker",
      "route": "/file-picker",
      "status": "ready",
      "depends": [
        "shared_learning",
        "file_picker_bridge",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "iOS"
        ],
        "required_capabilities": [
          "file_selection"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "file_selection",
            "reason": "file_bridge_adapters_web_filename_only",
            "sources": [
              "packages/file_picker_bridge/lib/file_picker_bridge.dart"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/platform/file_picker/AI_ANALYSIS.md"
    },
    {
      "id": "online_video_player",
      "category": "platform",
      "path": "lib/modules/platform/online_video_player",
      "route": "/online-video-player",
      "status": "ready",
      "depends": [
        "shared_learning",
        "dio",
        "video_player",
        "video_player_web",
        "video_player_win",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "iOS"
        ],
        "required_capabilities": [
          "media_playback"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "media_playback",
            "reason": "media_backend_adapters",
            "sources": [
              "apps/flutter_forge/lib/modules/platform/online_video_player/module_entry.dart",
              "apps/flutter_forge/pubspec.yaml"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/platform/online_video_player/AI_ANALYSIS.md"
    },
    {
      "id": "biometric_auth",
      "category": "platform",
      "path": "lib/modules/platform/biometric_auth",
      "route": "/biometric-auth",
      "status": "ready",
      "depends": [
        "shared_learning",
        "flutter_biometric",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "iOS",
          "web",
          "windows"
        ],
        "required_capabilities": [
          "biometric_auth"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "biometric_auth",
            "reason": "biometric_biometricprompt_localauth_adapters",
            "sources": [
              "apps/flutter_forge/pubspec.yaml",
              "apps/flutter_forge/lib/modules/platform/biometric_auth/module_entry.dart"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/platform/biometric_auth/AI_ANALYSIS.md"
    },
    {
      "id": "system_notification",
      "category": "platform",
      "path": "lib/modules/platform/system_notification",
      "route": "/system-notification",
      "status": "ready",
      "depends": [
        "shared_learning",
        "forge_notification_bridge",
        "module_registry"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "iOS",
          "web",
          "windows"
        ],
        "required_capabilities": [
          "notification_posting"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "notification_posting",
            "reason": "notification_android_macos_local_adapters",
            "sources": [
              "packages/forge_notification_bridge/pubspec.yaml",
              "packages/forge_notification_bridge/lib/forge_notification_method_channel.dart"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/platform/system_notification/AI_ANALYSIS.md"
    },
    {
      "id": "webview",
      "category": "platform",
      "path": "lib/modules/platform/webview",
      "route": "/webview",
      "status": "ready",
      "depends": [
        "shared_learning",
        "module_registry",
        "webview_flutter",
        "webview_windows"
      ],
      "platform_support": {
        "target_platforms": [
          "android",
          "iOS",
          "macOS",
          "web",
          "windows"
        ],
        "excluded_platforms": [
          "iOS",
          "web"
        ],
        "required_capabilities": [
          "embedded_web"
        ],
        "unreviewed_dependencies": [],
        "optional_capabilities": [],
        "reasons": [
          {
            "capability": "embedded_web",
            "reason": "embedded_web_adapters",
            "sources": [
              "apps/flutter_forge/lib/modules/platform/webview/module_entry.dart"
            ]
          }
        ],
        "restriction": null,
        "features": {}
      },
      "analysis": "lib/modules/platform/webview/AI_ANALYSIS.md"
    }
  ]
}
