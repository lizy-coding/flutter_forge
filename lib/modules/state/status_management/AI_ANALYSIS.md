{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.state.status_management",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/state/status_management",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_routes.dart","module_root.dart","pages","widgets","state"],
  "owns": ["module_entry","module_ui","module_state","module_docs"],
  "depends": ["provider","flutter_riverpod","flutter_bloc","module_registry"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["app/app_routes.dart","app/route_paths.dart","app/state_flow_app.dart","features/bloc/bloc_route.dart","features/bloc/counter_bloc.dart","features/bloc/counter_event.dart","features/bloc/counter_state.dart","features/provider/models/counter_cn.dart","features/provider/models/counter_model.dart","features/provider/provider_future_route.dart","features/provider/provider_lifting_route.dart","features/provider/provider_route.dart","features/provider/provider_todo_route.dart","features/provider/widgets/granular_grid.dart","features/provider/widgets/provider_perks.dart","features/riverpod/riverpod_future_route.dart","features/riverpod/riverpod_lifting_route.dart","features/riverpod/riverpod_route.dart","features/riverpod/riverpod_todo_route.dart","module_entry.dart","shared/widgets/state_flow_scaffold.dart"],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"]
}
