{
  "schema": "flutter_forge.agent_docs.module_index.v1",
  "registry": "lib/module_registry/module_manifest.dart",
  "count": 25,
  "modules": [
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
      "id": "flutter_scene_3d",
      "category": "ui",
      "path": "lib/modules/ui/flutter_scene_3d",
      "route": "/flutter-scene-3d",
      "status": "ready",
      "depends": [
        "shared_learning",
        "flutter_scene",
        "vector_math",
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
              "apps/flutter_forge/test/modules/ui/flutter_scene_3d/flutter_scene_3d_test.dart"
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
      "analysis": "lib/modules/platform/dio_interceptor/AI_ANALYSIS.md"
    },
    {
      "id": "usb_detector",
      "category": "platform",
      "path": "lib/modules/platform/usb_detector",
      "route": "/usb-detector",
      "status": "ready",
      "depends": [
        "shared_learning",
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
        "required_capabilities": [],
        "unreviewed_dependencies": [
          "device_info_plus"
        ],
        "optional_capabilities": [],
        "reasons": [],
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
