{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.app.router",
    "kind": "app_layer",
    "package": "main_app",
    "path": "lib/app/router",
    "status": "active"
  },
  "entrypoints": ["app_router.dart","app_route_table.dart"],
  "owns": ["go_router_root","module_route_aggregation","module_home_index"],
  "depends": ["module_registry","modules/*/module_entry.dart","modules/*/module_routes.dart"],
  "mutates": ["app_route_table.dart","app_router.dart"],
  "files": ["app_route_table.dart","app_router.dart"],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze"]
}
