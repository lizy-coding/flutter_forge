{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.app",
    "kind": "app_index",
    "package": "flutter_forge_app",
    "path": "lib/app",
    "status": "active"
  },
  "entrypoints": [
    "app.dart",
    "app_bootstrap.dart",
    "app_platform_provider.dart",
    "adaptive_app_shell.dart",
    "creator_home_page.dart",
    "creator_profile.dart",
    "module_home_page.dart",
    "unsupported_module_page.dart",
    "category_navigation.dart",
    "navigation_policy.dart",
    "category_window_app.dart",
    "router/app_router.dart",
    "router/app_route_table.dart"
  ],
  "owns": [
    "host_bootstrap",
    "platform_snapshot_injection",
    "material_app_router",
    "router",
    "creator_home",
    "module_catalog",
    "title_search",
    "unsupported_module_route",
    "responsive_navigation_shell",
    "adaptive_category_navigation",
    "desktop_category_window_shell"
  ],
  "depends": [
    "go_router",
    "flutter_riverpod",
    "url_launcher",
    "module_registry",
    "shared/multi_window",
    "modules"
  ],
  "children": [
    "router/AI_ANALYSIS.md"
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
